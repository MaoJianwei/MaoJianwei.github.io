---
layout: post
title: SDN实战团分享（二十二）：ONOS开发实战之OVS Manager (Bootcamp 2016)
date: 2016-04-25 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: 今天我为大家带来一场ONOS实战分享，是我们小组在2016年ONOS Hackathon中的项目，OVS Manager。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
>  **SDNLAB 文章发表：[http://www.sdnlab.com/16623.html](http://www.sdnlab.com/16623.html)**

【SDNLAB编者的话】本文系SDN实战团微信群组织的线上技术分享整理而成，由北京邮电大学-毛健炜给大家带来ONOS开发实战之OVS Manager(Bootcamp 2016)的分享。

********************************* 
**嘉宾简介：**

<br />

![1-Myphoto](/resources/picture/2016/04/onosOvsManager/1-Myphoto.png)

<br />

**毛健炜，北京邮电大学，未来网络理论与应用实验室（BUPT FNL实验室），大四本科生。目前主要研究控制器的核心设计及基于南北向的开发。曾获得2015年全国高校SDN大赛一等奖和最佳创意奖；2016年ONOS首届全球黑客马拉松一等奖。**

********************************* 

# 分享正文

　　各位朋友们，大家好！我是毛健炜，来自北京邮电大学，未来网络理论与应用实验室（BUPT FNL实验室），目前是大四本科生。目前主要研究控制器的核心设计及基于南北向的开发。曾获得2015年全国高校SDN大赛一等奖和最佳创意奖；2016年ONOS首届全球黑客马拉松一等奖。

　　今天我为大家带来一场ONOS实战分享，是我们小组在今年ONOS Hackathon中的项目，OVS Manager。

# Agenda:

　　1. ONOS整体架构简介、ONOS子系统架构简介

　　2. App应用代码框架、运行机制简介

　　3. OVS Manager需求及技术分析

　　4. OVS Manager各项需求的功能实现

# 1. ONOS整体架构简介、ONOS子系统架构简介

　　ONOS开发，万变不离其宗，首先，我们来看经典的三张图：

<br />

![2-ONOS-share-figure-1](/resources/picture/2016/04/onosOvsManager/2-ONOS-share-figure-1.png)

<br />

　　ONOS Core的各个子系统按照（左二）图所示，可大致划分为红色和灰色两类，红色的子系统更侧重于网络本身的功能，经常与上下层交互，如拓扑、意图、统计、流目标等；灰色的子系统更偏向于系统内核的功能，如事件、存储、集群、角色、参数配置等。

　　Core首先通过同步的Service和异步的Listener提供Java API给上层深蓝色的Internal App，然后Core再与诸多Internal App一起，向上开放棕色的NBI北向接口给浅蓝色的External App。

　　ONOS Core的各个子系统均按照（右一）图的架构去设计，无论是Device、Link、Host、Topology，还是Storage、Cluster、Config，皆是如此。（某些子系统可能只有架构中的橘黄色接口，而没有下半部分的绿色接口，大家看源码时可以留意。）

　　中间的Manager是子系统的核心，向上为ONOS的其他子系统和App提供Service、AdminService两类接口，AdminService主要用于高级的管理功能；向下为不同的Provider提供ProviderRegistry用于向Manager注册自身、ProviderService用于向Manager提供通过南向协议等感知/收集到的数据。（下方的Adapter常称为Provider，可作为Manager的数据源。）另外，ONOS具有天生的分布式集群设计，cluster的不同instance中的同一个子系统，通过Store进行数据同步和事件的传送。

　　以Device子系统为例，核心是DeviceManager：

<br />

![ONOS-OVS-mananger-figure-2](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-2.png)

<br />

　　首先我们看implements部分，分别实现了DeviceService、DeviceAdminService、DeviceProviderRegistry

### 1. DeviceService

<br />

![ONOS-OVS-mananger-figure-3](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-3.png)

<br />

　　主要是获取网络中设备的信息，属于获取信息的功能

### 2. DeviceAdminService

<br />

![ONOS-OVS-mananger-figure-4](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-4.png)

<br />

　　属于操作设备的功能

### 3. DeviceProviderRegistry

<br />

![ONOS-OVS-mananger-figure-5](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-5.png)

<br />

![ONOS-OVS-mananger-figure-6](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-6.png)

<br />

　　主要提供Provider注册、解注册的功能。

　　其次，我们来看extends部分，继承了AbstractListennerProviderRegistry

<br />

![ONOS-OVS-mananger-figure-7](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-7.png)

<br />

　　在DeviceManager的启动和关闭时，分别调用：

<br />

![ONOS-OVS-mananger-figure-8](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-8.png)

<br />

　　通过继承，使得Device子系统拥有了支持事件机制的能力。

　　最后是各种Provider往Manager通过ProviderService接口上送数据的过程：
DeviceManager拥有一个内部类，实现了DeviceProviderService接口，用于接收各个Provider送上来的数据，以下是一个BgpTopologyProvider感知到设备连接上线的例子：

　　DeviceManager中：

<br />

![ONOS-OVS-mananger-figure-9](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-9.png)

<br />

![ONOS-OVS-mananger-figure-10](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-10.png)

<br />

　　DeviceManager继承的AbstractListennerProviderRegistry所继承的AbstractProviderRegistry中：

<br />

![ONOS-OVS-mananger-figure-11](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-11.png)

<br />

　　当BgpTopologyProvider向DeviceManager注册时，即为其生成一个ProviderService，并进行注册。

　　BgpTopologyProvider中：

<br />

![ONOS-OVS-mananger-figure-12](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-12.png)

<br />

　　在其启动的时候，向Devicemanager注册自身

<br />

![ONOS-OVS-mananger-figure-13](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-13.png)

<br />

　　在其有新的消息需要上报的时候，通过刚才register（）返回值得到的DeviceProviderService，去进行上报，此处是一个设备连接上线的消息。

# 2. App应用代码框架、运行机制简介

　　我们此处说的App指的是Internal App，也就是最开始的（左二）图中的深蓝色部分。

　　App理论上说是运行在ONOS支持之上的ONOS App，实际上他们是一个个运行在Karaf容器中的OSGI应用模块而已，相互独立，通过Karaf的机制去引用其他模块提供的服务，就连ONOS自身的各个子系统也是如此。所以普通Karaf中的应用能做的事情，在我们的App中也能做，区别在于我们此时针对性地使用ONOS各模块提供的服务，因此我们需要学习一下它们的设计特性和思想以及了解如何使用和扩展它们。

　　在介绍OVS Manager之前，我们先简单介绍一些ONOS App开发中基本的点，磨刀不误砍柴工：

### 1) APP功能部分的开发

#### 1. 关于App的建立、调试到热部署，可以参考我的博客上这篇文章：[《ONOS 实战分享（一）：项目建立、调试到热部署》](/2015/11/24/ONOS-in-Practice-for-Share-one-Project-Set-up-Debug-Hot-Deployment/)

　　下面直接从项目的代码切入。

#### 2. 初始项目框架如下：

<br />

![ONOS-OVS-mananger-figure-14](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-14.png)

<br />

　　这就是一个普通的MAVEN项目，main是项目功能代码，test是项目测试代码，主要作单元测试之用。

　　Main中目前只有一个代码文件：

<br />

![ONOS-OVS-mananger-figure-15](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-15.jpg)

<br />

　　主要有这两个要点：

> 1. ONOS采用Slf4j-api & slf4j-jdk14的统一日志系统
> 
> 2. 采用Felix.scr.annotation来进行模块Component的识别@Component；标识模块的启动@Activate、关闭@Deactivate和响应配置改变@Modified的入口函数。

#### 3. 引用Core或其他App的服务，也通过Felix.scr.annotation进行，使用@Reference：

<br />

![ONOS-OVS-mananger-figure-16](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-16.png)

<br />

　　正如此处，就可以通过DeviceService接口去使用Device子系统的服务了，如上即获取了全网的交换机信息。这也是使用同步Service Java API的例子。

#### 4. 使用Listener，异步获取信息的Java API，示例如下：

<br />

![ONOS-OVS-mananger-figure-17](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-17.png)

<br />

![ONOS-OVS-mananger-figure-18](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-18.png)

<br />

　　（上两图来自 bgprouter App）

<br />

![ONOS-OVS-mananger-figure-19](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-19.png)

<br />

![ONOS-OVS-mananger-figure-20](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-20.png)

<br />

　　（上两图来自fwd App）

　　PacketProcessor主要对应Openflow中的PacketIn消息，虽然没有EventListener的形，但有其意，也是一个异步过程。

### 2) App命令行接口（CLI）的开发

　　命令行接口主要指的是在ONOS Karaf中的命令行操作，该接口主要用于调用我们应用的某个功能，特别是将不同的输入参数处理和适配好之后，单次或者多次调用应用的功能。另外，我个人认为，在开发调试阶段，有一个debug的命令作为调试的入口是及其方便有效的。

　　我之前学习的时候，看网上的一些介绍文章讲的是将我们扩展的CLI放在ONOS的cli文件夹中集中管理，并且修改其目录下的xml配置文件。但我个人的观点是，这样的做法不适合App来采取。而是将App自己的CLI放在自己的工程目录下，连同配置文件自行管理。这也是ONOS中一些已有的App的做法。

> 不放在onos-cli中的理由有：
> 
> 1. 即使应用没有启动，命令也依然存在，并且可以补全使用，但是会红字报错。如果放在App工程中，则会随着App的启动而添加，关闭而删除。
> 
> 2. 每次修改都要重新编译onos自身的相应目录，而且修改出问题了可能影响较广。如果移除了App，还需要手动移除App命令代码。
> 
> 3. 不利于App的单独发布。

　　而且我们在源码中可以看到，很多App都将自己扩展的CLI放在自己的目录下。

　　讲解如何扩展，我们只需要看一下CLI命令的实现结构即可：

<br />

![ONOS-OVS-mananger-figure-21](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-21.png)

<br />

　　如上，就是整个CLI命令的实现结构了，其中，除了shell-config.xml应放在src/main/resources/OSGI-INF/blueprint目录，并无更多要求。

　　**好，接下来开始我们团队ONOS Bootcamp – OVS Manager项目的介绍**

# 3. OVS Manager需求及技术分析

> 项目需求：
> 
> 1. 能够创建自定义的两类OVS交换机
> 
> 2. 能够删除OVS交换机
> 
> 3. 能够查看网络中OVS交换机的信息
> 
> 4. 当不同类型的OVS交换机上线时，能够下发不同的固定流表
> 
> 5. 自定义一个新的交换机Pipeline

　　根据需求，我们做一些技术上的分析：

　　首先，创建、删除和查看交换机，需要通过OVSDB协议来进行，我们首先要了解OVSDB协议连接如何建立，ONOS对协议通道如何抽象：

　　对于OVSDB的连接，在我们的项目中，OVS一侧作为客户端，ONOS作为服务端。ONOS的监听需要安装以下feature后即可自动启动。因此，我们只需要让OVS主动连上来即可，通过如下命令：

<br />

```

sudo ovs-vsctl set-manager tcp:127.0.0.1:6640

```

<br />

　　在ONOS中通过feature:install命令安装以下四个OVSDB相关的feature（不然会在日志中报告Package依赖不满足的谜之错误）

<br />

![ONOS-OVS-mananger-figure-22](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-22.png)

<br />

　　在分析了Vtn这个App之后，我们了解到如果需要通过OVSDB进行操作，我们需要以下步骤：

　　首先，我们需要获得这个Device的DeviceId，形象地看，就是获得这条协议连接。由于ONOS将其抽象成了Device，那么也就意味着OVSDB是记录在Device子系统里面的。并且协议连接的建立和断开，分别被抽象成了Device的ADD和REMOVE。

　　因此，我们可以通过两种方式去获得这个DeviceId：

> 1. 通过DeviceService.getDevices，然后筛选Type为Controller的Device
> 
> 2. 通过DeviceListener筛选DEVICE_ADD事件并且筛出Type为Controller的Device

　　这两种方法各有利弊：

> 第一种，如果getDevices的时候连接尚未建立，那么我们将无法拿到这条连接（前提是，出于性能和系统资源的考虑，我们排除了开启线程专门get轮询的方案）
> 
> 第二种，如果App启动的时候连接已经建立，我们同样无法拿到这条连接。

　　由于这条OVSDB连接是我们应用的功能之本，因此，我们在项目中同时采取了以上两种方案，在@Activate的时候先注册监听器，确定可能即将建立的新连接能被及时抓到之后，再去getDevices筛选一次可能已建立好的旧连接，确保我们的App能拿到协议连接，正常工作。

　　其次，我们需要用这个Device的DeviceId，从DriverService中拿到一个让我们可以进行操作的Handler，这就是ONOS中的设备驱动（Driver）的操作句柄：

<br />

```

DriverHandler handler = driverService.createHandler(controllerId);

```

<br />

　　然后，获取驱动中与设置配置相关的行为接口（behaviour）：BridgeConfig bridgeConfig = handler.behaviour(BridgeConfig.class);
此时我们获得的是OvsdbBridgeConfig Class的一个对象引用：

<br />

![ONOS-OVS-mananger-figure-23](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-23.png)

<br />

　　最后，我们只需要调用右侧的两个接口即可实现我们的需求，查看则使用getBridges()即可。

　　**整体流程如下：**

<br />

![ONOS-OVS-mananger-figure-24](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-24.png)

<br />

　　然后，当不同类型的OVS交换机上线时，能够下发不同的固定流表。这里主要是两个点，区分不同类型、下发流表。

　　首先考虑，我们是采用CLI来触发交换机的创建，因此可以通过CLI的参数来指定交换机的类型，我们主要分为两种类型：Core、Access。

　　其次，由于ONOS对OVS的两种抽象Device、BridgeDescription，然而其中并无我们可以直接利用来区分类型的类似参数，同时，为了应用而去扩展内部的做法也不太好。最后我们考虑使用DeviceId号来区分类型。对于OpenFlow来说，DPID号为16位十六进制的字符串，我们规定，第八位是1的，为Core类型；是0的为Access类型。这样在后续的功能实现中，若要区分类型，只需解析字符串即可。

　　最后，下发流表，我们采用下发流表的最高层的抽象，流目标（FlowObjective），选用它也是为了能用到我们稍后的自定义Pipeline。

　　FlowObjectiveService是FlowRuleService的一个更高层抽象，二者在下发流表时需要输入的参数大同小异，同样需要通过建造者模式构建出TrafficSelector（Match Fields）、TrafficTreatment（Instructions），然后设置流的各种参数，再通过服务接口予以下发。我们推荐App通过更高抽象的FlowObjectiveService去操作流，可以减轻App的负担，使其更专注于业务功能的实现。这也是ONOS首席架构师Thomas先生所推荐的。

　　最后一个需求是，自定义一个新的交换机Pipeline。

　　我刚开始看到赛题的这一点时，误认为这个Pipeline就是Openflow的Pipeline，请教了Henry同学等大牛，并且阅读了OpenVSwitchPipeline的源码之后，发现其实不然：

　　OpenFlow的Pipeline是一种流表匹配的机制。

　　ONOS中的Pipeline是OpenFlow Pipeline中的多个流表的使用规划。

　　而非创建一条用于匹配的流水线，也就是说，即不能想成如果创建多个那么下面的交换机就有多条独立的流水线可以用于匹配，也不能想成如果不创建那么下面就没有匹配的能力了。

　　通常Pipeline是与不同品牌的交换机的硬件实现相关的，所以Pipeline通常由厂商来写，当然对于OVS来说我们就有自定义的空间了。（这块内容应该与Table Type Patterns(TTP)有所相关）

　　以ONOS中已有的OpenVSwitchPipeline为例，解释什么叫“流表的规划”：

<br />

![ONOS-OVS-mananger-figure-25](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-25.jpg)

<br />

　　Pipeline，在交换机上线之初，往交换机中下发了这些默认流表（Table-miss），其Instructions就是Goto-Table。

　　OpenVSwitchPipeline划分了以上六种表，0号表用于流量分类，其余表用于不同种类的匹配，以上展示的是Table-miss的情况下，包在OpenFlow Pipeline会怎么走。

　　使用FlowObjectiveService下发流需求时（或者理解成下发流表时），调用过程是这样：
FlowObjectiveService –> device-specific Pipeline -> FlowRuleService

　　再举一个容易理解的例子，使用时，如果我们通过FlowObjectiveService下发需求，需要同时匹配二层MAC和三层IP，那么在PipeLine里面可能会拆分这两种匹配需求，并形成两个流表中的两条流表项，通过FlowRuleService下发下去。也即最终下发的是一条匹配Mac的，一条匹配IP的，并且在匹配上MAC后，让包跳转到IP表去匹配IP，以此来达到同时匹配二者的目的。

　　虽然看起来这么做好像没有什么必要，我目前的理解是，Pipeline是与底层硬件实现紧密相关的，它的作用应该是与底层适配吧，希望有经验的伙伴们能给予解答。

出于我们赛题的需求，我们设计了以下这个简单的pipeline：

<br />

![ONOS-OVS-mananger-figure-26](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-26.png)

<br />

# 4. OVS Manager各项需求的功能实现

　　我们项目的整体设计如下：

<br />

![ONOS-OVS-mananger-figure-27](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-27.png)

<br />

　　项目目录如下：

<br />

![ONOS-OVS-mananger-figure-28](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-28.png)

<br />

　　项目实现的关键技术点都在如上的分享中讲解了，本想在此处为大家贴上代码，不过我重新看了一遍项目感觉也就是以上技术点 + 程序逻辑的组合，因此就不在这里为大家大量展示了。

　　我们的项目及所有资料在比赛结束当天已经在Github上开源

　　项目名称：[ONOS_OVS_Manager_Bootcamp2016](https://github.com/MaoJianwei/ONOS_OVS_Manager_Bootcamp2016)

　　项目链接：[https://github.com/MaoJianwei/ONOS_OVS_Manager_Bootcamp2016](https://github.com/MaoJianwei/ONOS_OVS_Manager_Bootcamp2016)

　　以上就是我本次为大家分享的内容，感谢大家的收看！在此也要感谢我的Hackathon团队的其他成员：张鹏@电信北研，金凌@电信上研，马田丰@北京联通

　　还要感谢张宇峰团长的分享邀请，初次分享有许多不足之处，还请大家多多指教，谢谢大家！

# Q & A

> **Q1：控制器连接交换机一般是通过控制网络，有没有通过业务端口控制一部分网络设备（一般用在控制网络没法连接的机动节点），onos在这方面有没有设计？**
> 
> A1：我目前还没有见到过这样设计的相关介绍，我后续会了解一下，您是指的Openflow，Netconf，OVSDB还是其他的什么呢？

> **Q2：有没有尝试用PTCP的方式与控制器交互？**
> 
> A2：听组员介绍是可以的，但需要更深入地从OVSDBbridgeConfig为入口去看一下怎么设置ONOS去主动连接的对端IP，我目前还没有试过，ovsdb相关的模块就这几个，应该不难找到配置的入口
> 
> <br />
> 
> ![ONOS-OVS-mananger-figure-29](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-29.png)
> 
> <br />

> **Q3：流表有多个行动，是都执行还是匹配一个就行？**
> 
> A3：从协议来看是都执行的，然后如果是有output，会先将包此时的状态复制保存，再发，然后Action set 和list还不一样

> **Q4：如何处理连接后默认流表啊？就是package_in后有默认流表。这个是不是也有其它模块下发流表？哪如果是，这种情况怎么处理？**
> 
> A4：但是Intent会在网络拓扑改变、链路或者节点故障、流表timeout的时候，自动重新下表，甚至自动重新寻路，我记得一开始只有LLDP和arp相关的表吧，然后我们注册了packetprocessor之后，还要向packetservice指定我们对什么样包首部的包感兴趣，然后它会下一条默认流表，帮我们拿这样的包上来，Openflow1.3跟1.0一个很大的不同就是table-miss的时候，默认是丢包，而不是上报。

> **Q5：Flow Objective 更贴近业务的理念makes sense，听起来好像跟 Intent 有相关？**
> 
> A5：是的，Intent也是使用的Flow Objective，Intent比Flow Objective多了流表的维护上，Flow Objective只是静态地将流需求放进pipeline适配一下然后就通过FlowRuleService生硬地下下去了。但是Intent会在网络拓扑改变、链路或者节点故障、流表timeout的时候，自动重新下表，甚至自动重新寻路。

> **Q6：控制器一般通过网络连接交换机的控制口，控制交换机。但是在网络中有些节点放的比较远，或者就是机动节点通过无线互联的，这些节点能否通过业务口与控制器连接。onos在这方面有过考虑吗？**
> 
> A6：这相当于是一种in-bound的控制方式吧？这是支持的

> **Q7：我看你们的APP在GUI上有实现，具体流程是怎样的啊？怎么把结果整合上去的？**
> 
> A7：我们当时是用GUI来展示命令行操作后的结果，没有改动呢。其实也没有特别的整合，就是用了一下GUI的一些基本的展示功能，比如删除交换机这个：
> 
> <br />
> 
> ![ONOS-OVS-mananger-figure-30](/resources/picture/2016/04/onosOvsManager/ONOS-OVS-mananger-figure-30.png)
> 
> <br />
> 
> 这是已有的Device页面

> **Q8：in-bound是什么，能详细说下吗？**
> 
> A8：控制方式分为两种，一种是out-bound，就是控制器与交换机通过独立的物理线路互联
> 
> 另一种是in-bound，利用控制器控制的网去控制。解释得有点绕，通常可能需要下流表去配通in-bound控制链路，这样openflow等控制报文才能传到远方的交换机，我记得用mininet做in-bound控制的资料不少。我不知道立即理解清楚你的表述没有，你可以先看看in-bound是不是符合你的意思，如果是的话，这关键就在于给交换机配置控制器IP的时候，配的可能就是与各个host同一个网段的IP（我上次看到的一个实验案例是这样）

********************************* 

【SDNLAB编者的话】SDN实战团微信群由Brocade中国区CTO张宇峰领衔组织创立，携手SDN Lab以及海内外SDN/NFV/云计算产学研生态系统相关领域实战技术牛，每周都会组织定向的技术及业界动态分享
