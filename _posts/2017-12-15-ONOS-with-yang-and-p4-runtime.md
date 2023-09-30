---
layout: post
title: ONOS架构中的YANG、P4 Runtime（整理我在 GNTC 2017 的演讲，附PPT下载）
date: 2017-12-15 19:00:00 +0800
comments: true
categories: SDN ONOS P4
excerpt: 很荣幸收到天地互连主办方和ONF组织的邀请，让我能够在2017年GNTC全球网络技术大会上，做了题为“ONOS架构中的YANG、P4 Runtime”的演讲。非常感谢各位工作人员对我的帮助与支持。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[https://www.sdnlab.com/20348.html](https://www.sdnlab.com/20348.html)**

　　

　　很荣幸收到天地互连主办方和ONF组织的邀请，让我能够在2017年GNTC全球网络技术大会上，做了题为“ONOS架构中的YANG、P4 Runtime”的演讲。非常感谢各位工作人员对我的帮助与支持。

<br />

![MaoGNTC_1280](/resources/picture/2017/12/onosYangP4/MaoGNTC_1280.JPG)

<br />

　　演讲中，我首先为大家解析了ONOS的架构设计和设计考量。然后，分析了ONOS新引入的基于YANG模型的动态配置能力，这使得ONOS能够管理和控制传统的路由和交换设备。接着，讲解了ONOS对协议无关思想的支持，目前ONOS针对P4 Runtime进行建模抽象和适配。最后，介绍了ONOS开源全球社区和中文社区的联系方式与基本情况。

　　以下是演讲胶片以及根据现场视频修正过的演讲文案，经过主办方同意，我在这里分享给大家。ONOS方面的中文资料还比较少，希望这次整理和分享能帮助大家更清晰地了解ONOS内部及其最新进展，摆脱对大系统的迷茫感，更多地参与到ONOS社区中来。

　　由于演讲时间的要求，讲解上有所侧重，如果有理解不清的地方，欢迎朋友们在社区里交流，也可以在文末留言评论，或给我发邮件。

　　

　　**排版上大体遵循讲解文字位于对应胶片下方的规则。**

　　配合官方演讲视频学习，效果更佳：[https://v.qq.com/x/page/g05184tpwqb.html](https://v.qq.com/x/page/g05184tpwqb.html)

　　演讲PPT下载： [Jianwei Mao - GNTC 2017 - ONOS with YANG and P4 Runtime](/resources/Document/Jianwei_Mao___GNTC_2017___ONOS_with_YANG_and_P4_Runtime.pdf) <br /><br />

<br />

![1](/resources/picture/2017/12/onosYangP4/1.png)

<br />

　　各位朋友们大家好, 我是毛健炜，来自北京邮电大学，未来网络理论与应用实验室，刘韵洁院士团队，现在是一名研二的研究生。今天非常有幸作为ONOS大使的一员，代表ONF组织，在这里跟大家讨论ONOS的最新进展，希望我们都能够有所收获。

<br />

![2](/resources/picture/2017/12/onosYangP4/2.png)

<br />

　　今天我们先简单介绍一下ONOS的基本情况和它的设计架构，之后，我们再讨论一下ONOS对YANG和动态配置的支持，以及对P4 Runtime的支持。最后再介绍一下ONOS开源社区的情况。

<br />

![3](/resources/picture/2017/12/onosYangP4/3.png)

<br />

　　ONOS，全称是开放网络操作系统，通常以控制器的身份为人所知。
它是由ON.LAB组织发起的一个开源项目，在与ONF组织合并之后，现在由ONF组织进行管理。ONOS从13年开始进行平台的原型设计，到14年十二月发布了第一个正式版本。ONOS采用了敏捷开发、持续集成的软件工程思想，不断迭代，大体上每个季度会发布一个新版本，在今年的九月十五号，已经迭代到了1.11版本，社区以一种L字母开头的鸟类为它命名，也称为Loon版本。

　　ONOS在设计之初，就瞄准了服务提供商网络，也就是运营商网络，这个从基础设施到业务形态再到性能要求都极具复杂性和挑战性的级别。它把自己定位成一个运营商网络的控制平台，可以应用于运营商网络的各个层面，从核心的广域骨干网，到城域网，蜂窝无线接入网，再到有线接入和汇聚网，等等。

<br />

![4](/resources/picture/2017/12/onosYangP4/4.png)

<br />

![5](/resources/picture/2017/12/onosYangP4/5.png)

<br />

　　针对运营商网络的需求，ONOS规定了这么四条设计原则：

> * 首要的是，高可用性，高可扩展性和高性能。这三点对运营商网络来说是尤为重要的。
>
> * 第二，要对网络资源进行高度抽象并简练地表示出来；
>
> * 第三，要做到协议无关以及对特定设备的驱动功能的无关；
>
> * 最后，是整个控制器系统的模块化，这一点保证了整个控制器软件架构的稳定性以及在支持新业务新需求方面的灵活性。
>

<br />

![6](/resources/picture/2017/12/onosYangP4/6.png)

<br />

　　在分析了运营商各类网络的复杂性和需求之后，ONOS从一开始就给自己标定了这样一个关键的性能要求，先定一个小目标。一方面，要有高吞吐率。要能够支持每秒钟在网络中建立上百万条的流路径，要能够支持每秒钟高达六百万次的网络操作。另一方面，要有高容量，能够装下多达1TB的网络运行数据。这对软件控制器来说是很有挑战的。

<br />

![7](/resources/picture/2017/12/onosYangP4/7.png)

<br />

　　针对运营商这样的网络需求、性能要求，并结合前面的设计原则，ONOS做出了这样的架构设计：

　　整体来看，从上到下平行地分为五层，其中最下面两层红色的部分通常把它统称为南向协议插件层。在这一层上实现诸如OpenFlow、NetConf这些直接跟设备进行通信的协议插件，它们负责跟设备打交道。

　　往上，依次是南向接口、核心层、北向接口，以及我们针对业务需求开发的网络控制应用，比如ARP代理、Segment Routing分段路由、SDN-IP这个SDN与传统网络对接的应用等等。

　　核心层将各种网元设备与它们的转发表、统计信息等统一进行抽象，通过北向接口向应用提供这些信息，然后应用利用这些信息去进行业务决策，并通过北向接口把决策告诉给我们的ONOS。最后，核心层把决策解析成命令，通过南向接口适配到相应的协议插件上，最终将命令下发给特定的设备。

　　

　　其中，我们看到，核心层写着Distributed，分布式的，没错，ONOS天生就是一个分布式集群化的软件控制器，既可以单点部署，也可以多点集群部署。

<br />

![8](/resources/picture/2017/12/onosYangP4/8.png)

<br />

　　集群部署时，虽然数据是分片冗余存储的，但是从业务逻辑和控制功能的角度上看，每一个节点都是完全相同，是互为冗余备份的。不同节点既可以分管多个设备，也可以负载均衡地去处理北向来的业务请求。如果有一个节点宕机，其他节点会自然接管工作。

　　

　　下面，我们把每一层展开，看一下。

<br />

![9](/resources/picture/2017/12/onosYangP4/9.png)

<br />

　　首先大家请看中间红色方框框住的部分，这就是我们的Core核心层。在这里要给大家介绍一个概念，Subsystem，子系统。之前我们提到ONOS的模块化，ONOS把内部的各个功能都进行了模块分块，大家看到的红色和灰色的每一个小方块都是一个子系统，左边灰色的部分是跟软件运行相关的基础性功能，比如说Application应用管理子系统、Cluster集群管理子系统。右边红色的部分是跟网络功能相关的内容，像有Device设备子系统、Statistics统计信息子系统。

　　特别要提一下的是第二行这个Driver设备驱动子系统。不同厂商、不同型号的设备能够支持的功能是不一样的，同一种功能在不同设备上的具体操作也有差异，这些device-specific特定于设备的东西，统统被隔离、囊括到Driver子系统里面去了，这样这些差异性就不会在整个系统里扩散。

　　这个红色框里的每一个小方块，都遵从统一的子系统设计架构，大家请看：

<br />

![10](/resources/picture/2017/12/onosYangP4/10.png)

<br />

　　图中左右两边表示的是同一个子系统，在集群中的两个不同节点上的工作状态。

　　上中下三层分别是我们的业务应用，核心层的子系统，南向协议插件。

　　两个节点上的这个子系统通过属于自己的蓝色Store组件进行事件收发和数据同步。

　　黄色的部分是北向接口，绿色是南向接口，红色的Protocols是协议插件中管理底层Socket通信的部分。

<br />

![11](/resources/picture/2017/12/onosYangP4/11.png)

<br />

　　好，这就是ONOS的全貌，五层设计，大道至简。

　　

　　下面我们来看今天的另一个重点，ONOS对YANG和动态配置的支持。

<br />

![12](/resources/picture/2017/12/onosYangP4/12.png)

<br />

![13](/resources/picture/2017/12/onosYangP4/13.png)

<br />

　　首先，我们来看，什么是配置呢？我们把对设备的管理分为两个方面，控制和配置。控制指的是对流量的管理，偏向于OpenFlow，比如调整流表，读取流表或者端口的统计数据。而配置指的是对设备运行参数的管理，偏向于NetConf，比如设置一个端口 up / down，配置路由协议的参数等等。

　　这其中，流量状态的改变是非常快的，在毫秒或者微秒级别。而配置信息的改变相对要慢得多，大概在分钟或者小时级别。

　　在部分传统设备中，也可以直接去配置流量的转发表。

<br />

![14](/resources/picture/2017/12/onosYangP4/14.png)

<br />

　　那我们为什么需要动态配置的能力呢？一方面，有了动态配置，ONOS就可以去管理传统的路由和交换设备了。

　　我们知道，在之前的很长一段时间里，ONOS的南向插件主要就是OpenFlow和OVSDB，所以人们通常会认为ONOS是一个面向白盒设备的SDN解决方案。

　　**但现在，这一种认识已经被完全颠覆了，ONOS已经拥有了一套对传统设备的完整支持。**

　　在协议接口方面，我们有YANG，有NETCONF，有RESTCONF。在信息管理和处理方面，我们有动态配置子系统，它是在ONOS的核心层横向扩展出来的，它的架构跟上述的子系统设计架构完全一样。

<br />

![15](/resources/picture/2017/12/onosYangP4/15.png)

<br />

　　另一方面，试想一个新的设备要上线，我们不可避免地要对它进行网络上的业务上的配置，特别是当这个设备开放的控制能力很有限时，我们就只能用配置的方式去管理它，因为配置是对设备最基本的操作了，就跟网工朋友们插上串口线去配置设备一样。当设备在网络中运行起来了，这时候我们可能想要提供新的定制化服务，有了ONOS提供的动态配置功能，我们就可以自动化地去部署和开通这项业务。

　　为了能够管理传统的网络设备，ONOS在核心层横向扩展了一个动态配置子系统。配置部分会借助YANG模型，同样横向扩展了一个YANG Runtime子系统。

<br />

![16](/resources/picture/2017/12/onosYangP4/16.png)

<br />

![17](/resources/picture/2017/12/onosYangP4/17.png)

<br />

　　我们首先看左侧YANG的部分，大体工作流程是，YANG模型描述文件经过YANG编译器生成YANG model的jar包，接着YANG 模型这个jar包可以被手工加载、或者由南向插件在连接到设备后自动加载进YANG 运行时子系统进行解析，随后动态配置子系统、北向的应用和南向的插件就都能够使用这个YANG模型了。

　　

　　在YANG 这边，需要提一下的是 YANG 文件编译的部分。

<br />

![18](/resources/picture/2017/12/onosYangP4/18.png)

<br />

　　我们可以借助BUCK、MAVEN这样的工具，把YANG 文件送入YANG 编译器生成模型的Java代码和schema模型描述文件，然后经过Java编译器的处理，把它们整体打包成YANG model的jar包。

　　在YANG编译器这块，针对Java语言的YANG编译器种类不多，而且它们要么是跟配套的软件程序耦合过紧，要么不能够完整支持YANG语言的各项特性。所以，ONOS自行开发了一套YANG的工具库，它一方面实现了离线和在线，对YANG文件的完整解析和编译，另一方面，这套工具与ONOS本身完全解耦，并作为第三方工具库开源。

　　

　　在动态配置子系统这边，需要关注的是信息存储的部分，这个Store就是我们刚才在子系统架构里看到的那个负责做事件收发和数据同步的Store组件。

<br />

![19](/resources/picture/2017/12/onosYangP4/19.png)

<br />

![20](/resources/picture/2017/12/onosYangP4/20.png)

<br />

　　它以一棵YANG树的形式去组织数据，可以不断向周边延伸。同时存储着配置数据和运行状态信息，也同时存储着业务和设备两方面的配置信息。树这种结构让我们能够很灵活地对节点进行增删改查。但是对于一个大规模的网络来说，随之而来的代价可能会超过这种灵活性带给我们的好处。比如我们用来寻址的元信息的大小，可能会远远超过我们要去操作的信息对象的大小。幸运的是，ONOS本身的集群分片存储机制，在一定程度上弥补了这个代价，提供了一个较好的性能。

　　同时，ONOS也正在寻找一种更好的替代方案，既能同时兼顾灵活性和可扩展性，又能提供极致的性能体验。

<br />

![21](/resources/picture/2017/12/onosYangP4/21.png)

<br />

　　好，这就是ONOS为了能够管理传统的网络设备，而设计实现的对YANG和动态配置的支持。剑指传统设备，灵活可扩展。

　　

　　下面我们来看今天的最后一个重点，ONOS对P4 Runtime的支持。

<br />

![22](/resources/picture/2017/12/onosYangP4/22.png)

<br />

![23](/resources/picture/2017/12/onosYangP4/23.png)

<br />

　　首先，ONOS要如何控制和配置数据平面可编程的设备呢？

　　我们知道，在很长的时间里白盒领域的控制协议就是OpenFlow，所以ONOS无论是内部对匹配转发的抽象还是开放给外部的相关的北向接口，都是围绕着OpenFlow来抽象和设计的。比如固有的匹配域类型，固有的动作种类，特别是在一些OpenFlow周边规范中还规定了固定的流表流水线。比如，在OF-DPA这个规范中，数据包需要先经过VLAN表的处理然后才能由ACL表处理。

　　现在P4是数据平面可编程的主流代表，我们看，P4是怎么样的，它的匹配域和动作域是任意定制的，它的流表流水线也是可变的。

　　

　　不变和可变，该如何统一到一起呢？

<br />

![24](/resources/picture/2017/12/onosYangP4/24.png)

<br />

　　首先，ONOS为了解决这个问题，在Core层诸多子系统中，横向扩展了一个子系统，叫做PI 框架。PI，代表了协议无关、程序无关、以及处理流水线的无关。PI框架是围绕着P4和PSA进行建模的，但PI框架在设计上是面向通用的协议无关思想的，能容纳未来各种协议无关的语言或者协议，目前仅仅是适配到了P4语言。PSA就是P4设备的一个通用架构描述，类似OpenFlow的TTP。

　　PI架构里包含了一些类、服务和设备驱动的功能描述来建模和控制可编程数据平面，定义了抽象的表项和计数器等等。

<br />

![25](/resources/picture/2017/12/onosYangP4/25.png)

<br />

　　现在我们看到的就是PI框架在ONOS中的架构设计，首先，最下面是协议插件，有P4 Runtime和gRPC的，往上是Driver子系统，有P4Runtime、Tofino和BMv2的，正在开发的还有gNMI这个做管理的等等。其中，Tofino这个驱动按照计划将会在12月1号发布的ONOS 1.12版本中正式发布。再往上，核心层，就是PI框架本体所在，包含了这么三大块，PI模型，FlowRule Translation流表翻译子系统，还有Pipeconf子系统。其中把不变与可变统一起来的关键，就是这个流表翻译子系统。

　　PI框架向上既可以支持pipeline无感知的应用，也就是之前我们针对其他设备，比如OpenFlow设备去编写的程序；也可以支持对Pipeline有感知的应用，也就是针对特定的P4程序去编写的控制应用。

　　假设现在我们写好了P4程序，需要用ONOS去控制这样的设备，那我们就需要开发一个ONOS应用，这类应用我们把它称作Pipeconf，pipeline configuration，编译打包完的这个Pipeconf.oar文件加载到控制器之后，控制器就知道P4设备里将要运行着一个什么样的流水线，该如何去控制和使用这个流水线，同时控制器会帮我们把这个P4程序下发安装到我们的P4设备上。

　　

　　一切变化都在这个Pipeconf里面，我们来详细看一下。

<br />

![26](/resources/picture/2017/12/onosYangP4/26.png)

<br />

　　Pipeconf是以一个ONOS应用的形式呈现的，编译完就是我们熟悉的.oar文件。里面打包了一切必要的数据和代码，主要包括三个方面：

　　首先，是pipeline的模型，这是对P4程序解析后得到的结果，包括转发表的模型、计数器的模型等等。

　　第二，设备驱动功能。这个特别重要。这里面包含了这么几个要素：

> 1. 是Pipeline’s Interpreter，转发表流水线的解释器，它主要做的是类型转换的工作，这个很重要，我们稍后会看到。
>
> 2. 是一个可选的FlowObjective’s Pipeliner，这个其实在OpenFlow中对应的也有。FlowRule是具体表示了一条转发表，而FlowObjective是我们想要达成的转发目标，FlowObjective是FlowRule的更高层的抽象。一个转发目标可能对应到一个特定设备上的多条流表。这个Pipeliner就负责进行FlowObjective到FlowRule的转换。
>
> 3. 是一个可选的PortStatisticsDiscovery。比方说，我们写的P4程序里对端口的数据收发做了统计，我们在控制器上需要读取这些统计值，那么我们就需要给它加一个PortStatisticsDiscovery，端口统计发现这样的驱动功能。这个是可选的。如果说我们就想做一个ping通的实验，不需要这个统计功能，那么OK，就省去了这块的功夫。
>

　　第三，是设备平台相关的一些扩展。这些是P4程序编译后的产物，包括了BMv2 的JSON文件，Tofino的Binary固件，还有P4Info这个文件。其中P4Info很关键，它是在P4 Runtime中，把ID号和具体名字做映射的时候用的。

<br />

![27](/resources/picture/2017/12/onosYangP4/27.png)

<br />

　　下面我们来看PI架构在具体的场景下是如何工作的。

　　我们后续图中红色表示ONOS核心层的部分，绿色是设备驱动的部分，蓝色是我们的pipeconf应用。

　　

　　首先，是设备发现和连接上线。

　　在OpenFlow里面，通常我们是在设备上配好控制器的IP和端口号，然后设备上电以后主动连接控制器。

　　那在PI架构里面：

> * 首先，我们把编译好的pipeconf应用加载进ONOS，它会注册到PI架构的Pipeconf服务中去。
>
> * 然后，我们有两种方式告诉ONOS我们有哪些设备，一种是提前在netcfg.json这个网络配置文件里写好设备P4 Runtime gRPC服务的IP、端口号、要用哪个pipeconf、使用哪个设备驱动等信息；另一种是动态地调用Rest API把这些信息传递给控制器。
>
> 　　这些信息会传递给中间的General Device Provider，它会从Pipeconf service里面获取相应的pipeconf，并且绑定到相应的设备驱动上。
>
> * 最后，General Device Provider会去使用这个设备驱动跟P4设备建立连接，并且把pipeconf对应的P4程序给部署到P4设备中去。这里是P4程序动态部署的一步。
>

　　

　　经过上面这个流程，P4设备就在ONOS里正常上线了。

　　

<br />

![28](/resources/picture/2017/12/onosYangP4/28.png)

<br />

　　下面我们来看怎么操作流表：

　　PI框架里的流表操作涉及到三个阶段的转换操作，分别对应Pipeliner、Interpreter、P4Info这三个元素。也就是图中的蓝色部分，是我们pipeconf应用里的内容。

> * 首先，如果我们是使用FlowObjective来下发决策，那么会经过Pipeliner，Pipeliner把它转换成FlowRule，当然我们也可以直接使用FlowRule。
>
> * 然后，P4设备驱动会调用PI框架的FlowRule Translation 子系统，借助Interpreter把FlowRule转换成PI Table Entry，它是PI框架对一条表项的抽象。
>
> * 最后PI Table Entry会在南向协议插件的P4Runtime Client中借助P4Info转换成P4 Runtime Message这个通信报文，然后在网络中传输给P4设备。
>

　　

　　流表操作，三次转换。

　　

<br />

![29](/resources/picture/2017/12/onosYangP4/29.png)

<br />

　　最后，我们来看怎么样完成packet-in和packet-out的操作。这两个操作跟OpenFlow是类似的。

　　

> * 首先，我们看右边。在OpenFlow里面我们也会用到图中的第一块，Packet Service，不同的是在下面，对接的是PI框架的Packet Provider，因为在P4里面，数据包的格式是我们自定义的，所以在这里借助我们的Interpreter进行数据包的解析。解析之后，生成Inbound/Outbound Packet，它们都是ONOS中原有的对packet-in/out的抽象。
>
> * 接着，这里借助P4 Runtime设备驱动将其转换成PI Packet Operation，它是PI框架中对包操作的抽象。
>
> * 最后，再通过南向插件与设备交互，在这里同样借助P4Info完成PI框架抽象对象与通信报文的转换。
>

　　

　　在ONOS的源码中，现在已经有了一个名为p4-tutorial的示例应用，在onos/apps目录下，有兴趣的朋友可以详细看一下。

<br />

![30](/resources/picture/2017/12/onosYangP4/30.png)

<br />

　　在介绍P4 Runtime的最后，我们来梳理一下，协议无关，我们需要做什么工作：

> * 首先，编写P4 程序；
> 
> * 然后编译它，得到P4Info等文件；
> 
> * 然后再编写和编译Pipeconf应用，这时会自动把我们的P4Info、BMv2 JSON、Tofino Binary等相关的资源文件都打包进去；
> 
> * 再然后，就是根据我们的业务需要，去编写网络控制应用，pipeline有感知的或者无感知的都行。当然，由于数据平面具有灵活的可编程性，编写ONOS应用这一步也可以被提到最前面。
> 
> * 最后，就请尽情享受ONOS给您带来的无限可能！
>

<br />

![31](/resources/picture/2017/12/onosYangP4/31.png)

<br />

![32](/resources/picture/2017/12/onosYangP4/32.png)

<br />

　　最后希望大家能在ONOS社区里分享对ONOS的任何想法，贡献代码，提交项目，大家可以在ONOS 的wiki页面找到 **[邮件列表](https://wiki.onosproject.org/display/ONOS/Mailing+Lists)** 与全球的伙伴们交流，也可以加入中文社区，**ONOS研究群（QQ群：454644351）**，还可以在SDNLAB网站上找到全面的ONOS相关资讯和技术文章。

<br />

![33](/resources/picture/2017/12/onosYangP4/33.png)

<br />

　　以上就是我想跟大家讨论的内容，ONOS的架构以及ONOS对YANG和P4 Runtime的支持，如果我有什么地方讲得不清楚的，欢迎大家下来找我讨论，也欢迎朋友们给我发邮件指正，我的邮箱是[maojianwei2012@126.com](mailto:maojianwei2012@126.com)，请多指教，谢谢大家！

　　

　　由于演讲时间的要求，讲解上有所侧重，如果有理解不清的地方，欢迎朋友们在上述ONOS社区里交流，也可以在文末留言评论，或给我发邮件。

