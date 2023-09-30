---
layout: post
title: Microsoft Azure中的SONiC架构简析
date: 2017-11-28 19:00:00 +0800
comments: true
categories: SDN SONiC
excerpt: 学术界和工业界已经有各种方式能够实现数据平面可编程、数控分离集中控制，但还没有一个公开的清晰的方式来实现设备的控制平面可编程。SONiC可以说是瞄准了这个空白。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[https://www.sdnlab.com/20309.html](https://www.sdnlab.com/20309.html)**

　　SDN发展至今，数控分离的完全集中式控制在实践中一些关键点上明显地变得捉襟见肘。人们逐渐意识到不应该从完全分布式的极端走向完全集中式这另一个极端，而应该中庸地看待集中式与分布式的关系。比如需要全局视野去追求最优化的工作应该上提到集中式的控制器来做，对时间敏感的故障FRR收敛等功能还是应该下放到设备上去完成。

　　学术界和工业界已经有各种方式能够实现数据平面可编程、数控分离集中控制，但还没有一个公开的清晰的方式来实现设备的控制平面可编程。SONiC可以说是瞄准了这个空白。

　　SONiC，全称Software for Open Networking in the Cloud，定义了路由交换设备的控制平面的容器化架构，定义中包含组件与接口。其中具体工作的组件合称为SSWS，SWitch State Service。二者通常不需要太刻意地区分。

　　如下三张图，SONiC广泛应用在微软Azure全球各地的云数据中心中，并且主要部署在数据中心网络的ToR接入层和Leaf层。

![1](/resources/picture/2017/11/sonic/1.png)

![2](/resources/picture/2017/11/sonic/2.png)

![3](/resources/picture/2017/11/sonic/3.png)

<br />

　　下面我们专注于SONiC架构本身。如图所示，SONiC是架构在路由交换设备的ASIC、Linux内核、设备驱动之上，在各种协议应用和设备配置应用之下的一层，可看作是一个应用与硬件驱动之间的接口层。

![4](/resources/picture/2017/11/sonic/4.png)

　　SONiC向下通过SAI接口对接不同的硬件平台，硬件平台的厂商需要提供一个SAI接口的具体实现，这个SAI接口的实现通常也被称为ASIC SDK，它向下可能会对接更为底层的位于Linux内核层的ASIC驱动。SAI的实现根据上层的要求，可以去操作设备中的ASIC、传感器、光纤收发器等硬件。

　　SONiC的核心是一个非关系型数据库，目前开源版本选用的是Redis。这个数据库被逻辑地切分为两块，分别是APP_DB数据库和ASIC_DB数据库。APP数据库是由上层的应用根据业务需要去写入的业务数据。ASIC数据库中的内容一方面是由APP数据库中的内容转换成的直接对硬件进行操作的符合SAI接口标准的配置数据；另一方面是由SAI的实现主动上报的从硬件中获取的数据。

　　SONiC中有三种关键组件。Orchestration Agent组件负责上述APP_DB和ASIC_DB之间的信息转换工作。SSWS Syncd组件通过与Redis数据库对接，负责在ASIC_DB与SAI的实现之间拷贝、传递数据。最后一种是对接各个外围应用和设备功能的syncd组件。

　　SONiC向上通过各种syncd组件对接各个应用，例如通过fpmsyncd对接BGP路由应用。目前SONiC支持的syncd组件有fpmsyncd转发平面控制、intfsyncd逻辑接口控制、neighsyncd邻居和下一跳信息管理、portsyncd物理端口控制、teamsyncd链路聚合组(LAG)控制等。

　　不同组件操作数据库中逻辑上的不同数据表，具体规范可参见：[SONiC Architecture](https://github.com/Azure/SONiC/wiki/Architecture#switch-data-service-database-schema)；[SONiC SWitch State Service](https://github.com/Azure/sonic-swss/blob/master/doc/swss-schema.md)

　　整个SONiC数据库对外围的Orchestration Agent、SSWS Syncd、syncd组件与自己互通的接口进行了规定，称为Object Library。各组件与数据库的通信采用C/S模式，并且支持发布订阅机制。

　　SONiC中包括Redis数据库、Orchestration Agent、SSWS Syncd、各个syncd组件在内的所有部分，都以容器的形式运行在路由交换设备的控制平面。上层的路由协议应用、设备管理应用也以容器的形式运行。

<br />

　　下图是一个SONiC Demo中的一页，这个Demo展示了目前SONiC在Microsoft Azure全球数据中心中的应用。Demo视频：[SONiC: Enabling Fast Evolution in the Network](https://www.youtube.com/watch?v=DvFTCpwnUQ4)

　　图中第一个箭头处，例如database对应着Redis数据库、swss对应着Orchestration Agent、bgp对应着BGP路由协议应用。第二个箭头处，登陆进了bgp容器的命令行，并查阅了bgp的配置和运行状态简报。第三个箭头处，登陆进了redis 数据库容器的命令行，即将查阅的是设备上所有的路由表信息，路由表信息如下面第二、第三张图。

![5](/resources/picture/2017/11/sonic/5.png)

![6](/resources/picture/2017/11/sonic/6.png)

![7](/resources/picture/2017/11/sonic/7.png)

<br />

　　目前SONiC开源版本的发展还处于初级阶段，正在适配包含Arista、Barefoot、Centec、Edge-core等在内的各厂家设备，以及P4-BMv2软件交换机。感兴趣的朋友可以接触一下。

## 参考文献

> [1] [SONiC开源库信息梳理](https://github.com/Azure/SONiC/blob/gh-pages/sourcecode.md)
> 
> [2] [目前SONiC在Microsoft Azure全球数据中心中的应用Demo视频](https://www.youtube.com/watch?v=DvFTCpwnUQ4)
> 
> [3] [SONiC数据库数据格式规范1](https://github.com/Azure/SONiC/wiki/Architecture#switch-data-service-database-schema)
> 
> [4] [SONiC数据库数据格式规范2](https://github.com/Azure/sonic-swss/blob/master/doc/swss-schema.md)
> 
> [5] [SAI接口的介绍](https://www.youtube.com/watch?v=7fbDsK2yE2I)
