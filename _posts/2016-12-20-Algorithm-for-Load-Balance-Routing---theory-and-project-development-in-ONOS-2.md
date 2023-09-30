---
layout: post
title: ONOS：负载均衡路由算法及应用开发（二）
date: 2016-12-20 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: 本文将为大家讲述应用的实现，并进行必要的代码分析。本项目开源在笔者的Github：ONOS_LoadBalance_Routing_Forward
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/18276.html](http://www.sdnlab.com/18276.html)**

　　上篇文章笔者主要讲述了负载均衡的原理：[《ONOS：负载均衡路由算法及应用开发（一）》](/2016/10/11/Algorithm-for-Load-Balance-Routing-theory-and-project-development-in-ONOS-1/)

　　本文将为大家讲述应用的实现，并进行必要的代码分析。

　　本项目开源在笔者的Github：[ONOS_LoadBalance_Routing_Forward](https://github.com/MaoJianwei/ONOS_LoadBalance_Routing_Forward)

　　本应用暂时以Maven作为项目的构建工具，并采用最简单的single bundle的项目组织形式[1]。如果进行大项目的开发，推荐仿照onos.faultmanagement应用进行模块划分和项目feature组织。

　　虽然ONOS在最新的1.8.0-SNAPSHOT版本中强制引入了BUCK项目构建工具，但本应用开发时尚未有这个要求。大家在开发自己的应用时仍可使用Maven，但如果想要贡献代码，则必须添加兼容BUCK构建工具的配置信息。
　　
　　

# 一、Maven项目POM文件

　　为了便于各位理解，必要的讲解已经写在了注释中。

## 　1.App属性信息


```xml
<!-- Mao: Application Identifier -->
    <groupId>org.mao</groupId>
    <artifactId>onos-app-mao-load-balance</artifactId>
    <packaging>bundle</packaging>

    <!-- Mao: Application Readable Info -->
    <description>Mao Load Balance Routing</description>
    <url>http://maojianwei.github.io/</url>

    <properties>
        <!-- Mao: ONOS App Info for Jersey REST API & Swagger UI -->
        <web.context>/onos</web.context>
        <api.version>1.0.0</api.version>
        <api.title>Mao Load Balance Routing REST API</api.title>
        <api.description>
            APIs for interacting with the Mao Load Balance application.
        </api.description>
        <api.package>org.fnl.rest</api.package>

        <!-- Mao: ONOS App Info for maven packaging -->
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <onos.version>1.8.0-SNAPSHOT</onos.version>
        <onos.app.name>org.onosproject.mao.loadbalance</onos.app.name>
        <onos.app.title>Mao Load Balance Routing</onos.app.title>
        <onos.app.origin>Mao Jianwei, FNLab, BUPT</onos.app.origin>
        <onos.app.category>Traffic Steering</onos.app.category>
        <onos.app.url>http://maojianwei.github.io/</onos.app.url>
        <onos.app.readme>Mao Load Balance Routing</onos.app.readme>
</properties>
```

<br />

## 　2.App依赖

```xml
<dependencies>
        <!-- REST API -->
        <dependency>
            <groupId>org.glassfish.jersey.containers</groupId>
            <artifactId>jersey-container-servlet-core</artifactId>
            <!--<version>2.22.2</version>-->
        </dependency>

        <!-- PortStatisticsService -->
        <dependency>
            <groupId>org.onosproject</groupId>
            <artifactId>onos-incubator-api</artifactId>
        </dependency>

        <!-- DefaultTopology -->
        <dependency>
            <groupId>org.onosproject</groupId>
            <artifactId>onos-core-common</artifactId>
            <version>1.8.0-SNAPSHOT</version>
        </dependency>
</dependencies>
```

<br />

#  二、代码分析

## 　1.源码目录总览

<br />

![yuan_ma_mu_lu](/resources/picture/2016/12/onosLB/1_yuan_ma_mu_lu.png)

<br />

　　主要包含如下两个部分：
    
> * MaoRoutingManager：负载均衡Reactive Routing核心模块
> * MaoRoutingService：预留供引用的模块服务接口

<br />

## 　2. 负载均衡核心模块MaoRoutingManager

<br />

　　使用ONOS提供的基础服务，加粗的是本应用重点使用的服务：

| 服 务                       | 用 途                                              |
| -------------------------- | -------------------------------------------------- |
| CoreService                | 注册应用模块，获取ApplicationId                      |
| IntentService              | 下发/撤销数据流的路由决策                             |
| TopologyService            | 获取网络当前拓扑                                     |
| HostService                | 获取客户机的抽象对象Host                              |
| **DeviceService**          | **获取设备端口的抽象对象Port，从中获取端口的工作速率**   |
| **PortStatisticsService**  | **获取链路连接点ConnectPoint的当前发送速率**           |
| PacketService              | 添加/移除数据包处理器；注册/撤销网络应上报的数据包的特征  |

<br />

　　从主模块MaoRoutingManager的角度看，模块内部设计和功能划分如下：

![MaoRoutingManager_Design](/resources/picture/2016/12/onosLB/2_MaoRoutingManager_Design.png) <br />

<br />

整体上划分为两个重要部分：

> * BandwidthLinkWeight：链路带宽度量值计算器。符合ONOS选路算法的设计规范。
> * InternalPacketProcessor：数据包处理器。包含流量处理的入口函数，以及本文路由算法所需的函数

<br />

### 　a) BandwidthLinkWeight

<br />

　　这是一个工具类，实现了ONOS定义的LinkWeight接口，主要服务于选路算法函数，作用是计算指定链路的权值(Weight)。LinkWeight接口定义如下：

<br />

![ONOS_LinkWeight_interface](/resources/picture/2016/12/onosLB/3_ONOS_LinkWeight_interface.png) <br />

<br />

　　BandwidthLinkWeight的具体功能是计算链路当前剩余带宽所占的百分比，以此作为链路的权值。计算过程中需要获取链路的工作速率和当前速率。如果链路失效或链路容量已满，则返回最大值100%，意指链路满载。其实现如下：

<br />

```Java
/**
 * Tool for calculating weight value for each Link(TopologyEdge).
 *
 * @author Mao.
 */
private class BandwidthLinkWeight implements LinkWeight {

    private static final double LINK_WEIGHT_DOWN = 100.0;
    private static final double LINK_WEIGHT_FULL = 100.0;

    @Override
    public double weight(TopologyEdge edge) {

        if (edge.link().state() == Link.State.INACTIVE) {
            return LINK_WEIGHT_DOWN;
        }

        long linkWireSpeed = getLinkWireSpeed(edge.link());

        long interLinkRestBandwidth = linkWireSpeed - getLinkLoadSpeed(edge.link());

        if (interLinkRestBandwidth <= 0) {
            return LINK_WEIGHT_FULL;
        }

        // 当前剩余带宽百分比
        return 100 - interLinkRestBandwidth * 1.0 / linkWireSpeed * 100;
    }

    ...

}
```

<br />

　　其中使用到以下四个辅助函数：

> * getLinkWireSpeed：返回链路的工作速率；暂定以两端工作速率的最小值作为链路工作速率。
> * getLinkLoadSpeed：返回链路的当前速率；暂定以两端发送速率的最大值作为链路当前速率。
> * getPortWireSpeed：获取端口的工作速率；
> * getPortLoadSpeed：获取端口的当前发送速率。


```java
private long getLinkWireSpeed(Link link) {

    long srcSpeed = getPortWireSpeed(link.src());
    long dstSpeed = getPortWireSpeed(link.dst());

    return min(srcSpeed, dstSpeed);
}

private long getLinkLoadSpeed(Link link) {

    long srcSpeed = getPortLoadSpeed(link.src());
    long dstSpeed = getPortLoadSpeed(link.dst());

    return max(srcSpeed, dstSpeed);
}

/**
 * Unit: bps
 */
private long getPortLoadSpeed(ConnectPoint port) {

	//data source: Bps
    return portStatisticsService.load(port).rate() * 8;
}

/**
 * Unit bps
 */
private long getPortWireSpeed(ConnectPoint port) {
    assert port.elementId() instanceof DeviceId;

    //data source: Mbps
    return deviceService.getPort(port.deviceId(), port.port()).portSpeed() * 1000000;
}
```

<br />

### 　b) InternalPacketProcessor

　　为了便于展示，暂时将负载均衡路由算法的入口函数和算法四步骤的相关函数[2]都移到了数据包处理器中。源码库中的包处理器只保留了process主函数，其余的都移到了主模块中。由于本算法可以作为独立的路由算法使用，因此可将负载均衡路由功能独立出来，作为本应用对外提供的一项服务，即添加相应的API在预留的MaoRoutingService模块服务接口中。

　　包处理器内部分为两部分。第一部分是流量处理的入口，以下省略了数据检查和并发同步的部分，只保留了关键逻辑的代码，完整源码可浏览Github仓库。

```java
@Override
public void process(PacketContext context) {
    Ethernet pkt = context.inPacket().parsed();
    if (pkt.getEtherType() == Ethernet.TYPE_IPV4) {

        // 根据MAC生成主机标识ID
        HostId srcHostId = HostId.hostId(pkt.getSourceMAC());
        HostId dstHostId = HostId.hostId(pkt.getDestinationMAC());

        // 为两个主机的该条流量选择一条路由路径
        Set<Path> paths = getLoadBalancePaths(srcHostId, dstHostId);

        // 构造流量匹配域
        IPv4 ipPkt = (IPv4) pkt.getPayload();
        TrafficSelector selector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_IPV4)
                .matchIPSrc(IpPrefix.valueOf(ipPkt.getSourceAddress(), 32))
                .matchIPDst(IpPrefix.valueOf(ipPkt.getDestinationAddress(), 32))
                .build();

        // 使用任意一条路径结果
        Path result = paths.iterator().next();

        // 构造PathIntent路径意图
        PathIntent pathIntent = PathIntent.builder()
                .path(result)
                .appId(appId)
                .priority(40123)
                .selector(selector)
                .treatment(DefaultTrafficTreatment.emptyTreatment())
                .build();

        // 提交流量路径决策
        intentService.submit(pathIntent);
    }
}
```

<br />

　　第二部分是路由算法实现部分。以下是算法实现中所有函数的调用关系和算法流程图，请先关注右上方的图例。

![Mao_LoadBalance_Algorithm](/resources/picture/2016/12/onosLB/4_Mao_LoadBalance_Algorithm.png) <br />

<br />

　　先回忆一下在上一篇文章（见上文链接）中，笔者提到算法过程中几种结果集的名称：

　　**可选路由路径 → 优选路由路径 → 最优路由路径**

<br />

　　首先，本实现提供了两个便利的算法入口，可默认采用ONOS感知的实时拓扑进行路由计算，也可根据自定义的拓扑进行计算。

　　其次，在第一步的探路过程中，暂时使用DFS深度优先查找算法，进行递归查找，同时在算法实现中考虑了路由环路的预防。此处使用到ONOS对拓扑图的三个抽象TopologyGragh、TopologyEdge和TopologyVertex，分别表示图、边和顶点。

　　第二步，算权值。借助BandwidthLinkWeight计算路径中每一条链路的权值，然后以最大的链路权值作为该条路径的权值。利用表征链路的各个TopologyEdge对象和算出的路径权值，生成ONOS中的路由路径抽象对象Path。

　　第三步，选路。如下图，首先通过getMinCostPath选出“优选路由路径”，再通过getMinHopPath选出“最优路由路径”。

　　第四步，铺路。在buildEdgeToEdgePath中将源点的第一跳链路与目的的第一跳链路分别接在最优路由路径的前后两端，并更新其路径权值。

<br />

![select_route](/resources/picture/2016/12/onosLB/5_select_route.png) <br />

<br />

# 参考文献

[1] [ONOS 实战分享（一）：项目建立、调试到热部署](http://www.sdnlab.com/15197.html)

<br />
