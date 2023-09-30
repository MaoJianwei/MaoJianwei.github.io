---
layout: post
title: ONOS：从Device Subsystem看ONOS子系统设计（1）：Core层基本功能架构
date: 2017-03-24 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: ONOS的内核是由诸多遵循同一架构设计的子系统组成的，Device Subsystem设备子系统就是其中重要的一员。笔者将借助其源码讲解ONOS Core层的架构设计。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/18758.html](http://www.sdnlab.com/18758.html)**

　　ONOS的内核是由诸多遵循同一架构设计的子系统组成的，Device Subsystem设备子系统就是其中重要的一员。笔者将借助其源码讲解ONOS Core层的架构设计。本连载不会过多讲解设备子系统本身的工作细节，相关内容可以阅读笔者后续的源码分析文章。

　　本文撰稿时最新源码版本为1.10.0-SNAPSHOT，2017.03.13。<sup>[1]</sup>

　　笔者正在未来网络、软件设计的学习之路上步步前行，一点浅见，还望朋友们多多指点，不吝赐教 :)

<br />

![ONOS-Core-Tier-Architecture-Design](/resources/picture/2017/03/onosSubsystemCore/1-ONOS-Core-Tier-Architecture-Design.png)

<br />

　　以上是ONOS的架构设计图<sup>[2]</sup>。Core层包含了设备管理、拓扑管理、数据流管理和网络意图管理等功能，它们共同构成了ONOS的核心。每种功能都被独立设计成一个子系统，遵循右图中的架构设计，并行扩展。

　　图中，左侧Core层对应着右侧的Manager Component，橘黄色的方格是给各个ONOS App提供的北向接口，绿色的是给各个南向协议插件Provider提供的南向接口，蓝色的是在集群环境中，多个节点上的同一子系统之间通信的接口。

　　下面让我们走进Core的世界 :)

　　好的架构设计可能不会让问题更容易解决，但它让问题不会发生。

　　Core在设计上首先遵循了“针对接口编程，不针对实现编程”的面向对象设计原则[3]。将子系统提供的服务功能抽象成接口，呈现给顶层的应用和底层的协议插件。这样做有两个优势：

　　其一，实现了不同功能模块的解耦。顶层和底层在使用子系统提供的功能时，只需要了解系统能为其做什么，不需关心系统怎么去做。当子系统内部的实现需要升级或替换整个子系统模块时，顶层和底层看到的接口是始终不变的，因而不需要做任何的修改。

　　其二，顶层应用和底层协议插件是不同类别的模块，应用是为了实现特定的应用场景或网络功能，协议插件是为了支持控制器与网络设备进行信息传递。因此面向二者可以将接口划分为两类，面向应用的Service和面向协议插件的Provider。另外，应用这个范畴本身也可以分为两类，一类服务于网络功能，比如运行某种路由算法，进行某种虚拟化的信息管理和配置映射；另一类担当着网管的角色，比如下线某台设备，切断某条链路。由此，管理功能又从Service中抽离出来，成为AdminService。二者就像是user和root的关系，通常AdminService会直接继承Service。不同种类的接口自成不同的功能集，这些接口的功能可能是由同一个系统模块去实现。顶层和底层，需要子系统提供的功能不同，自然只需要使用不同的接口。这样既避免了对系统其他部分产生干扰的可能，减小故障定位的难度，也避免了开发者同时面对众多功能函数时心生迷惑。

　　下面以设备子系统为例具体讲解，Device Subsystem的Manager Component声明如下：

<br />

![Device-Manager-Component-Declaration](/resources/picture/2017/03/onosSubsystemCore/2-Device-Manager-Component-Declaration.png)

<br />

> 核心DeviceManager：
> 
> * 实现了以下四个接口：
> 
> 　　　　1. Service　→　DeviceService
> 
> 　　　　2. AdminService　→　DeviceAdminService
> 
> 　　　　3. ProviderRegistry　→　DeviceProviderRegistry
> 
> 　　　　4. 额外　→　PortConfigOperatorRegistry
> 
> * 通过内部类InternalDeviceProviderService实现了接口：
> 
> 　　　　ProviderService　→　DeviceProviderService
> 
> * 继承了一个抽象类AbstractListenerProviderRegistry

　　Service提供了获取系统所管理的内容及其详细信息的能力，并且引入了事件机制，允许添加异步监听器Listener。通过DeviceService能获取具体设备和端口的类对象，它还包含了获取设备的各类信息的接口，如设备数量、设备端口统计信息和设备控制权信息等。

　　AdminService提供了相比于Service而言更高级别的管理能力。通过DeviceAdminService我们不仅仅能够获取设备的信息，还能够命令设备下线、改变设备端口的启用状态等。

　　ProviderRegistry使各种Provider能够将自身注册进子系统，以便向系统提供数据，接受系统的指令去完成特定的工作。DeviceProviderRegistry提供了简单的注册/注销功能。

　　ProviderService使各种Provider能够主动、异步地将最新数据提交给子系统。通过DeviceProviderService，Provider能够上报设备上下线事件、上报设备控制权变更结果、提交端口统计信息等。DeviceManager通过内部类InternalDeviceProviderService实现了该接口。

　　另外，Provider接口是由数据提供者去实现，是提供给Manager Component使用的，让数据提供者能够接受系统的指令去完成特定的工作。这个数据提供者通常指南向协议插件。通过DeviceProvider能够告知南向协议插件本集群节点是否对某一设备具有控制权，能够检测设备是否依然在线，能够询问某一种南向协议插件是否与设备建立了协议连接等。

　　由于DeviceManager在Listener和Provider的管理上没有特殊的要求，就直接继承了包含通用的管理功能的AbstractListenerProviderRegistry类。

　　最后，由于设备子系统自身的工作需要，额外实现了PortConfigOperatorRegistry接口，供读写设备端口配置的模块使用。该接口目前仅被操作光设备的App使用。

　　各接口和内部类的详细定义如下图：

<br />

![Device-Subsystem-detailed-Declaration-of-Interfaces-and-Classes](/resources/picture/2017/03/onosSubsystemCore/3-Device-Subsystem-detailed-Declaration-of-Interfaces-and-Classes.png)

<br />

　　Core层的基本功能架构可由如下类图做简单回顾：

<br />

![UML-of-Core-Device-Subsystem](/resources/picture/2017/03/onosSubsystemCore/4-UML-of-Core-Device-Subsystem.png)

<br />

　　一点浅见，还望朋友们多多指点，不吝赐教 :)

　　下一回，《神秘的Store接口和集群事件机制》，各位看官，欲知后续如何，请听下回分解…

<br />

# 参考文献

[1] [ONOS官方Git库](https://gerrit.onosproject.org)：git clone https://gerrit.onosproject.org/onos

[2] [ONOS Wiki：System Components](https://wiki.onosproject.org/display/ONOS/System+Components)

[3] 《Head First设计模式（中文版）》，P11，面向对象设计原则

<br />
