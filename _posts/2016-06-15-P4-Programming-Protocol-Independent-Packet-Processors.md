---
layout: post
title: P4：编写协议无关的包处理器
date: 2016-06-15 19:00:00 +0800
comments: true
categories: SDN P4
excerpt: P4是一门编写协议无关的包处理器的高级语言。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/17107.html](http://www.sdnlab.com/17107.html)**

　　本文为论文翻译，论文原文：[P4 Programming Protocol-Independent Packet Processors](/resources/Document/P4_Programming_Protocol-Independent_Packet_Processors.pdf)

# 摘要

　　P4是一门编写协议无关的包处理器的高级语言。P4与SDN控制协议联合在一起工作，比如OpenFlow。在OpenFlow当前的协议形态中，它精确地指定了供它操作的协议头。这个协议头集合已经在短短的几年时间中，从12个域增长到了41个域，这同时也增加了协议的复杂性，但是仍然没有提供添加新的自定义首部的灵活性。

　　在这篇论文中我们将P4作为一个展示了OpenFlow在未来应该如何演进的草案协议而提出。

> 我们有如下三个目标：
> 
> 1. 匹配域的重配置能力：在交换机被部署之后，开发者应该能够改变交换机处理数据包的方式；
> 
> 2. 协议无关性：交换机不应该被绑定在任何特定的网络协议上；
> 
> 3. 目标无关性：开发者应该能够在不关注底层特定硬件设备的前提下描述包处理功能。

　　我们以下将会以如何使用P4配置交换机来添加一个新的分层次的标签为例，讲解以上三个目标。

# 第一章 介绍

　　软件定义网络（SDN）给予网络运营者对他们的网络进行可编程控制的能力。在软件定义网络中，控制平面与转发平面物理隔离，并且一个控制平面可以控制多个转发设备。同时，转发设备可以通过多种方式被编程，它们都拥有一个通用的、开放的、厂商无关的接口（比如OpenFlow）。这一点也使得一个控制平面能够控制来自不同硬件和软件厂商的转发设备。

<br />

　　表1-1 OpenFlow标准支持的匹配域

![table-1-1-openflow](/resources/picture/2016/06/P4/1-table-1-1-openflow.png) <br />

<br />

　　OpenFlow接口一开始很简单，只抽象了单个规则表，并且表中只能在数据包特定的十二个首部区域上进行匹配（比如MAC地址、IP地址、载荷协议类型、TCP/UDP端口等等）。在过去的几年中，协议标准已经演进得越来越复杂（如表1-1），归结起来就是支持匹配越来越多的首部区域和支持多级的规则表，由此能够允许交换机向控制器暴露出它们更多的能力。

　　新首部区域的增多过程没有表露出任何即将结束的迹象。例如，数据中心网络的运营者越来越想要使用新的包封装形式（比如NVGRE、VXLAN和STT），他们采取部署软件交换机的方式来达到这个目的，因为软件交换机更容易扩展新的功能。相比重复地扩展OpenFlow的协议标准，我们认为未来的交换机应该为包解析和首部域匹配支持灵活的机制，允许控制器应用通过一个通用的开放的接口利用交换机的这些能力（例如新的“OpenFlow 2.0”接口）。比起如今的OpenFlow 1.x标准，上述这样一个通用的可扩展的方法将是更简单、更优雅也更不会过时的。

　　近段时间的芯片设计方案表明，这样的灵活性可以在定制的ASIC上实现太比特级的速率<sup>[1,2,3]</sup>。编写这种新一代的交换芯片是非常不容易的。每一个芯片有其自身的低级接口，类似于微码编程。在本篇论文中，我们概述了一种编写协议无关的包处理器（P4）的高级语言的设计。图1-1展示了P4和已有的协议接口之间的关系。P4用来配置交换机。告诉它们应该如何处理数据包。已有的协议接口（例如OpenFlow）负责将转发表送入固定功能的交换机。P4为编程控制网络提升了抽象等级，作为一个控制器与交换机之间的普通接口进行工作。换言之，我们相信未来几代的OpenFlow协议应该允许控制器“告诉交换机如何去做”，而不受固有的交换机设计的局限。关键的挑战是要找到一个折衷点，它要能够平衡“能够灵活表达多种控制意愿的特性需求”与“在大范围的软硬件交换机上实现的低难度”要求。

<br />

　　图 1-1 P4是一门交换机配置语言

![P4-figure-1](/resources/picture/2016/06/P4/2-P4-figure-1.png) <br />

<br />

> 在设计P4的时候，我们有三个主要的目标：
> 
> 1.重配置能力：控制器应该能够重新定义数据包的包解析过程和对首部区域的处理过程；
> 
> 2.协议无关性：交换机不应该与特定的包格式绑定。相反地，控制器应该能够指定：
> 
> 　　1)一个能提取出特定名称和类型的首部区域的包解析器
> 
> 　　2)一个类型化的用于处理这些首部区域的“匹配 – 动作”表的集合
> 
> 3.目标无关性：正如C开发者不需要知道底层具体是什么CPU在工作一样，控制器的开发者不必知道底层交换机的细节。而是P4编译器在将目标无关的P4描述转换成目标相关的用来配置交换机的程序时，才应该去考虑交换机的能力。

　　本文的行文思路如下：我们从介绍一个抽象的交换机转发模型开始。然后我们讲解了当下对一门描述协议无关的包处理过程的语言的需求。我们接着举一个简单而又有积极性的例子，这个例子讲述的是一个网络的运营者想要支持一个新的数据包首部区域，并且分多个阶段去处理数据包。我们通过这个例子来探索P4程序是如何指定首部、包解析器、多个“匹配 - 动作”表和多个表之间的控制流程的。最后，我们讨论P4编译器如何将P4程序映射到目标交换机上。

　　其他相关研究。2011年，Yadav et al. [4]为OpenFlow提出了一种抽象转发模型，但没有强调编译器这一角色。Kangaroo <sup>[1]</sup> 提出了可编程包解析的概念。最近，Song <sup>[5]</sup> 提出了协议无关转发（POF），它参考了我们协议无关的目标，但是它的关注点更偏向于网络处理器（NP）。ONF提出了流表编写模式（TTP），用来表达交换机的匹配能力<sup>[6]</sup>。近期有关NOSIX<sup>[7]</sup> 的一些工作也参考了我们“匹配 – 转发”表这一灵活的设计标准，但没有考虑到协议无关性，也没有提出一门能够指定解析器、规则表和控制流程的语言。近期的其他一些工作提出了一种可编程接口，服务于数据平面的监控、拥塞控制和队列管理<sup>[8, 9]</sup>。模块化的路由器Click <sup>[10]</sup> 支持软件层面灵活的包处理，但没法将这些处理程序映射到大量的目标硬件交换设备上。

# 第二章 抽象的转发模型

　　在我们的抽象模型中（图2-1），交换机通过一个可编程的解析器和随后的多阶段的“匹配 – 执行动作”的流程组合转发数据包，其中“匹配 – 执行动作”的过程可以是串行的、并行的或者是二者结合的。源于对OpenFlow的探索，我们的模型包含了三个一般化。首先，OpenFlow假设有一个固定的包解析器，在这一点上我们的模型能够支持可编程的解析器，允许定义新的协议首部。第二，OpenFlow假设“匹配 – 执行动作”的各个阶段是串行的，在这一点上我们的模型允许它们是并行的或串行的。第三，我们的模型假设“动作”是使用交换机所支持的协议无关的原语编写而成的。

　　我们的抽象模型将数据包如何在不同的转发设备上（例如以太网交换机、负载均衡器、路由器）被不同的技术（例如固定功能的ASIC交换芯片、NPU、可重配置的交换机、软件交换机、FPGA）进行处理的问题一般化了。这就使我们能够发明一门通用的语言来描绘如何根据我们通用的抽象模型处理数据包。因此，开发者可以开发目标无依赖的程序，开发者可以映射这个程序到大量不同的转发设备中，这些设备覆盖从相当慢的软件交换机到最快速的基于ASIC芯片的交换机。

　　这个转发模型受两类操作控制：配置和下发。配置操作编写了包解析器，设置了“匹配 – 执行动作”各阶段的顺序，指定了每个阶段要处理的协议首部区域。配置操作决定了支持哪种网络协议，也决定了交换机可能会如何处理数据包。下发操作将表项添加到“匹配 – 动作”表中，或从其中移除。其中，表本身是在配置操作的时候指定好的。下发操作决定了在任意给定时刻应用到数据包上的执行策略。

　　出于这篇论文的讲述目的，我们假设配置和下发是两个独立的阶段。特别地，交换机不需要在配置的阶段处理数据包。同时，我们期望未来的具体实现能够允许数据包无论是在部分配置完成还是完全配置好的时候，都能够被处理，也即允许在配置升级的时候，包处理过程没有任何的暂停。我们的模型慎重考虑和鼓励实现不打断转发过程的重配置。

　　显而易见，配置阶段对于固定功能的ASIC来说是没有意义的；对于这类交换机，P4编译器的工作是简单地检查芯片是否能够支持P4程序。相反地，正如<sup>[2, 3]</sup>中所描述，我们的目标是把握快速可重配置的包处理流水线的一般趋势。

　　到达的数据包首先被包解析器处理。我们假设数据包的数据内容是与包首部分开缓存的，并且不能够用来进行匹配。解析器从包首部中找出并提取某些区域，这也即定义了交换机所支持的协议。这个模型没有对协议首部的含义做任何假设，仅仅是解析后的数据包的表现形式定义了一个首部区域的集合，“匹配 – 执行动作”的过程就在这个集合上进行。

　　提取出来的首部区域接下来会被传递到“匹配 – 动作”表。这个表被分为入口表和出口表两部分。虽然两个表都可能会修改包首部，但是入口的“匹配 – 动作”决定了是数据包将去往哪一个出口，也决定了数据包将被放入哪一个队列。基于入口的处理结果，数据包可能会被转发、复制（为了组播、SPAN端口监控或发往控制平面）、丢弃或触发流量控制。出口的“匹配 – 动作”在包首部上为每一个动作目标单独做一轮修改，比如在组播复制数据包的时候所做的。动作表（计数器、流量监管器policer等）可以与一条流关联起来，追踪其每一帧的状态。

<br />

　　图 2-1 抽象转发模型

![P4-figure-2](/resources/picture/2016/06/P4/3-P4-figure-2.png) <br />

<br />

　　数据包可以在其被处理的不同阶段之间携带额外的信息，称作metadata元数据。元数据可以同等地被当成一个数据包首部区域。元数据的一些例子有入端口号、传输目的地和队列、用于数据包调度的时间戳，以及在表与表之间传递的数据，这些数据不涉及改变数据包解析后的表现，比如虚网标识号。

　　排队策略的处理方式同当前OpenFlow的一样：通过一个动作将一个数据包映射到一个队列中，这个队列是为了接收特定服务策略而配置的。服务策略（例如最低速率、DRR轮询）的选择是交换机配置的一部分。

　　尽管超出了本文的范围，动作原语可以加入模型中，从而允许开发人员实现新的或已有的拥塞控制协议。例如，交换机可能会被编程去基于新的条件设置ECN比特位，或者交换机可能会使用“匹配 – 动作”表实现一个私有专用的拥塞控制机制。

# 第三章 一门编程语言

　　我们使用上述的抽象转发模型来定义一门语言，用以表达交换机将如何被配置，数据包将如何被处理。本文的主要目标是提出这门P4编程语言。尽管如此，我们意识到在这个领域以后可能会有多种语言诞生，并且他们可能都包含了我们在这里描述到的通用特性。比如，这样的语言需要一种方式来表达解析器是如何被编程的，由此解析器能够知道它应该处理什么样的数据包格式；因此开发者需要一种方法来声明什么样的首部类型是可能会出现并被处理的。例如，开发者可以指明IPv4首部的格式，以及什么样的首部可能合法地遵循了IP首部。通过声明合法的首部类型促进了P4中的定义解析。相似地，开发者需要表达数据报首部将如何被处理。例如，TTL字段必须被递减和检测，新的隧道首部可能需要被添加，校验和可能需要重新校验。这促使P4作为一种必要的控制流程序，通过使用已声明的首部类型和动作的原语集合，来描述首部区域的处理过程。

　　我们可以使用像Click这样的语言，Click使用C++编写成的模块构建交换机。Click是极富表现力的，非常适合表达数据包在CPU内核中应该如何被处理。但它不完全符合我们的需求。我们需要一门能够将“解析 – 匹配 – 动作”流水线映射到指定的硬件上的语言。另外，Click不是为控制器 – 交换机架构而设计的，因此不允许开发者描述当被修改的时候能够动态下发更新的“匹配 – 动作”表。最后一点，Click使人们更难以推断出限制并发运行的依赖。我们后续将讨论这一依赖。

　　一门数据包处理语言必须允许开发者暗示或明示首部区域之间任何串行化的依赖。这种依赖决定了哪些表可以并行执行。例如，由于IP路由表和ARP表之间的数据依赖，它们是需要串行执行的。依赖可以通过分析TDGs表依赖图而识别；这些图描述了输入的首部区域、动作和表之间的控制流程。图3-1展示了一个二层/三层交换的表依赖图的例子。

　　这引领我们提出一种两步编译过程。在顶层，开发者使用必要的能描绘P4控制流的语言来编写数据包的处理程序；在这一层之下，编译器将对P4的描述翻译成TDG表依赖图，以促进依赖的分析，然后编译器将会把TDG映射到具体的交换机对象上。P4的设计可以让P4程序翻译到TDG的过程更加容易。总的来说，P4可以被认为是Click的普适性和OpenFlow 1.0的不灵活性一个折衷点。Click的普适性让依赖的推测和映射到硬件的过程变得困难；OpenFlow 1.0的不灵活性让重配置协议的处理过程变得不可能。

<br />

　　图 3-1 二层/三层交换的TDG表依赖图

![P4-figure-3](/resources/picture/2016/06/P4/4-P4-figure-3.png) <br />

<br />

# 第四章 P4语言示例

　　我们通过深入地测试一个简单的例子来探索P4。许多网络的部署分为边缘和核心两种；终端主机直接连接在边缘设备上，边缘设备之间通过后方的高带宽核心网互联。所有的协议都设计去支持这样的架构（比如MPLS<sup>[11]</sup>和PortLand<sup>[12]</sup>），主要目的是简化核心网的转发工作。

　　考虑到一个简单二层网络的部署，边缘的TOR交换设备通过两层的核心连接在一起。我们假设终端主机的数量在不断增长，并且核心层的二层转发表即将存满溢出。MPLS是一个简化核心层的选择，但实现一个多标签的分布式标签协议是一项困难到令人怯步的任务。PortLand看起来看有趣，但是它要求重写MAC地址（这可能破坏已有的网络调试工具的正常工作），并且要求有新的客户端来回应ARP请求。

　　P4是我们能够表达一种个性化的解决方案，同时只需要对网络架构做出做小限度的改变。我们将这个方案称为mTag：它结合了PortLand的分层路由思想和类似MPLS的简单标签。穿过核心层的路由路径被编码成四个单字节的区域，四个区域组成一个32位的标签。这个32位的标签可以携带“源路径”或目的地的定位（就像PortLand的Pseudo伪装MAC一样）。每一个核心交换机只需要检查标签里的一个字节就可以进行交换转发。尽管标签可以由终端主机的网卡添加，但是在我们这个例子中，标签由第一个TOR交换机添加。

　　这个简单的mTag例子将我们的注意力集中到P4语言上。实践中实现整个交换功能的P4程序将比这复杂很多倍。

### 4.1 P4概念

　　P4程序包含以下关键元素的定义：

> 1. 首部Headers：首部的定义描述了一系列首部区域的顺序和结构。它包含区域长度的规范，约束了区域数据的取值。
> 
> 2. 解析器Parsers：解析器的定义描述了如何识别数据包内的首部和有效的首部顺序。
> 
> 3. 表Tables：“匹配 – 动作”表是执行数据包处理的机制。P4程序定义的首部区域可能会用于匹配，或者在其上执行特定的动作。
> 
> 4. 动作Actions：P4支持通过更简单的协议无关的原语构造复杂的执行动作。这些复杂的动作可以在“匹配 – 动作”表中使用。
> 
> 5. 控制程序Control Programs：控制程序决定了“匹配 – 动作”表处理数据包的顺序。一个简单又必要的程序描述了“匹配 – 动作”表之间的控制流。

　　接下来，我们将展示P4中的这些元素，每一个是如何在一个理想化的mTag处理器的定义上起作用的。

### 4.2 首部格式

　　从首部格式的规范开始设计。有几种特定领域语言也提出了首部格式的设计<sup>[13, 14, 15]</sup>；P4借用了许多他们的想法。通常地，每一个首部的详细阐述都是通过声明一个各首部区域名称和长度的有序列表来完成。可选的首部区域注解允许我们约束区域的取值范围或可变长区域的最大长度。例如，标准的以太网和VLAN首部被详细阐述如下：

<br />

```json
header ethernet {
    fields {
        dst_addr : 48; // width in bits
        src_addr : 48;
        ethertype : 16;
    }
}

header vlan {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        ethertype : 16;
    }
}
```

<br />

　　mTag首部可以直接添加，而不必替换已有的这些声明。首部区域名称表明核心层有两层的汇聚。每一个核心交换机都被编写了一些规则来检查这些字节中的某一个。具体检查哪一个字节，是由交换机在层次中所处的位置和数据流的方向（上或下）决定的。

<br />

```json
header mTag {
    fields {
        up1 : 8;
        up2 : 8;
        down1 : 8;
        down2 : 8;
        ethertype : 16;
    }
}
```

<br />

### 4.3 数据包解析器

　　P4假设底层交换机可以实现一个状态机，这个状态机能够自头至尾横贯数据包的各个首部，随着状态机的行进提取首部区域的值。提取出来的首部区域值被送入“匹配 – 动作”表进行处理。

　　P4把状态机直接描述成从一个首部到下一个首部的过渡转移的集合。每一个过渡转移可能会被当前首部中的值触发。例如，我们按如下内容描述mTag状态机：

<br />

```json
parser start {
    ethernet;
}

parser ethernet {
    switch(ethertype) {
        case 0x8100: vlan;
        case 0x9100: vlan;
        case 0x800: ipv4;
        // Other cases
    }
}

parser vlan {
    switch(ethertype) {
        case 0xaaaa: mTag;
        case 0x800: ipv4;
        // Other cases
    }
}

parser mTag {
    switch(ethertype) {
        case 0x800: ipv4;
        // Other cases
    }
}
```

<br />

　　数据包的解析从start状态开始，一直行进直到到达了明确的stop状态或是遭遇到无法处理的情况（这可能被标记成错误）。在到达了对应下一个首部的状态时，状态机根据首部的规范描述提取出首部，然后根据状态机的下一个过渡转移继续向前行进。提取出来的首部被送往交换机流水线后半部分的“匹配 – 执行动作”的处理过程。

　　mTag的解析器是非常简单的：它只有四种状态。真实网络中的解析器会要求有比这多上许多的状态；例如，Gibb et. al. <sup>[16, Figure 3(e)]</sup> 定义的那个解析器就扩展到了一百多种状态。

### 4.4 表的规范

　　接下来，开发者需要描述定义好的首部区域将在“匹配 – 执行动作”阶段如何进行匹配（比如它们应该被精确匹配，范围匹配还是通配符匹配），以及当成功匹配之后将执行什么动作。

　　在我们简单的mTag例子中，边缘交换机匹配二层目的地和VLAN ID，然后选择一个mTag添加到首部中。开发者定义一张表来匹配这两个首部区域，以及执行一个添加mTag首部的动作（见后文）。其中的reads属性声明了要匹配哪些首部区域，同时限定了匹配类型（精确匹配、三重匹配等）。actions属性列出了“匹配 – 动作”表可能会对数据包执行的动作。动作将会在本文后续部分讲解。max_size属性指明了“匹配 – 动作”表需要能够支持多少条表项。

　　表的规范允许P4编译器决定存储表需要多大的存储空间，以及在什么样的存储器（比如TCAM或SRAM）上实现这个表。

<br />

```json
table mTag_table {
    reads {
        ethernet.dst_addr : exact;
        vlan.vid : exact;
    }

    actions {
        // At runtime, entries are programmed with params
        // for the mTag action. See below.
        add_mTag;
    }

    max_size : 20000;
}
```

<br />

　　为了展示的完整性和后续讨论的便利，我们在此展示其他表的简短定义，这些表将在控制程序一节（§4.6）中引用。

<br />

```json
table source_check {

    // Verify mtag only on ports to the core

    reads {
        mtag : valid; // Was mtag parsed?
        metadata.ingress_port : exact;
    }

    actions { // Each table entry specifies *one* action
        // If inappropriate mTag, send to CPU
        fault_to_cpu;
        // If mtag found, strip and record in metadata
        strip_mtag;
        // Otherwise, allow the packet to continue
        pass;
    }

    max_size : 64; // One rule per port
}

table local_switching {
    // Reads destination and checks if local
    // If miss occurs, goto mtag table.
}

table egress_check {
    // Verify egress is resolved
    // Do not retag packets received with tag
    // Reads egress and whether packet was mTagged
}
```

<br />

### 4.5 动作的规范

　　P4定义了一个基本动作的集合，可以利用它们构造复杂的动作。每个P4程序都声明了一个动作功能的集合，动作功能由动作原语编写而成；这些动作功能简化的表的规范和下发。P4假设一个动作功能中的原语是并行执行的。（没有并行执行能力的交换设备可能会模拟并行的过程。）

　　适用于上述的add_mTag动作的实现如下：

<br />

```json
action add_mTag(up1, up2, down1, down2, egr_spec) {
    add_header(mTag);
    // Copy VLAN ethertype to mTag
    copy_field(mTag.ethertype, vlan.ethertype);
    // Set VLAN’s ethertype to signal mTag
    set_field(vlan.ethertype, 0xaaaa);
    set_field(mTag.up1, up1);
    set_field(mTag.up2, up2);
    set_field(mTag.down1, down1);
    set_field(mTag.down2, down2);
    // Set the destination egress port as well
    set_field(metadata.egress_spec, egr_spec);
}
```

<br />

　　如果某个动作需要有输入参数（例如mTag中的up1值），参数将会在运行时由匹配表提供。

　　在这个例子中，交换机将mTag标签插入在VLAN标签之后，复制VLAN标签的Ethertype字段到mTag中，以指明后续载荷是什么协议的封包，然后设置VLAN标签的Ethertype字段为0xaaaa，表明其后跟随的是mTag标签。在边缘交换机上执行的相反动作没有展示出来，这些动作将会从数据包中剥去mTag标签。

> P4的基本动作包括：
> 
> 1. Set_field：将首部中的某一特定区域设置为特定的值，支持带掩码的设置；
> 
> 2. Copy_field：将一个首部区域的值拷贝到另一首部区域中；
> 
> 3. Add_header：添加一个有效的特定的首部（以及它所有的首部区域）；
> 
> 4. Remove_header：从数据包中删除（pop取出）一个首部（以及它所有的首部区域）；
> 
> 5. Increment：递增或递减一个首部区域的值；
> 
> 6. Checksum：计算首部区域的一些集合的校验和（比如IPv4校验和）。

　　我们期望大多数交换设备上的实现将会约束动作的处理，只允许与特定的数据包格式相一致的首部修改操作。

### 4.6 控制程序

　　一旦表和动作被定义好，接下来仅剩的任务就是指定从一个表转移到下一个表的控制流。控制流作为一个程序通过一个函数、条件和表的引用组成的集合进行指定。

<br />

　　图 4-1 mTag例子的控制流程

![P4-figure-4](/resources/picture/2016/06/P4/5-P4-figure-4.png) <br />

<br />

　　图4-1为边缘交换机上的mTag实现展示了一个期望的控制流的图形化表示。在包解析之后，source_check表确认接收到的数据包和入端口是否一致。例如，mTag只应该存在于连接到核心交换机的端口上。source_check也会从数据包中剥去mTag标签，同时在元数据中记录数据包是否拥有mTag标签。流水线中后续的表可能会可能会匹配这个元数据以避免再次往数据包中添加标签。

　　local_switching表稍后将会被运行。如果没有匹配上，就意味着这个数据包的目的地不是连接在同一个交换机上的主机。在这种情况下，mTag_table表（上述定义的）将会用来匹配这个数据包。本地和送往核心层的转发控制都可以被egress_check表处理。这个表将会在转发目的地未知的情况下，上送一个通知到SDN控制层。

　　这一包处理流水线的必要描述如下：

<br />

```json
control main() {
    // Verify mTag state and port are consistent
    table(source_check);

    // If no error from source_check, continue
    if (!defined(metadata.ingress_error)) {
        // Attempt to switch to end hosts
        table(local_switching);

        if (!defined(metadata.egress_spec)) {
            // Not a known local host; try mtagging
            table(mTag_table);
        }

        // Check for unknown egress state or
        // bad retagging with mTag.
        table(egress_check);
    }
}
```

<br />

# 第五章 编译P4程序

　　为了让网络能够实现我们的P4程序，我们需要编译器来把目标无关的描述映射到目标交换机的特定硬件或软件平台上。完成这个工作涉及分配目标的资源并且为设备生成合适的配置。

### 5.1 编译包解析器

　　对于有可编程包解析器的设备，编译器将解析器描述翻译成解析状态机。对于固定的解析器，编译器仅仅确认解析器描述与目标设备的解析器是一致的。生成一个状态机的细节和有关状态表项的细节，可以在<sup>[16]</sup>中找到。

　　表5-1展示了上述解析器（§4.3）中vlan和mTag部分的状态表项。每一条表项指明了当前的状态、用于匹配的区域的值以及即将跳转的下一状态。为了展示的简洁性，其他行被忽略。

　　表 5-1 mTag例子的解析器状态表项：

Current State  |Lookup Value  |Next State
---------------|--------------|-------------
Vlan           |0xaaaa        |mTag
Vlan           |0x800         |ipv4
Vlan           |*             |stop
mTag           |0x800         |ipv4
mTag           |*             |stop

### 5.2 编译控制程序

　　§4.6中必要的控制流描述是一种方便的指定交换机的逻辑转发行为的方法，但它不能明确地表示出表之间的依赖和并发执行的机会。因此我们部署一个编译器来分析控制程序，帮助我们识别依赖以及寻找能够并发处理首部区域的机会。最终，编译器为交换设备生成目标配置。目标设备有很多种可能，例如软件交换机<sup>[17]</sup>、多核软件交换机<sup>[18]</sup>、NPU<sup>[19]</sup>、固定功能的交换机<sup>[20]</sup>，或是可重配置的匹配表（RMT）流水线<sup>[2]</sup>。

　　正如§3中所讨论的，编译器遵循两阶段的编译过程。它首先把P4控制程序转换成TDG表依赖图描述这样的一个中间结果，编译器分析这个描述以查明表之间的依赖。针对特定目标设备的第二步将会把这个依赖图映射到交换设备的特定资源上。

　　我们简单地梳理一下mTag这个例子将如何被映射到不同种类的交换设备中：

1.　软件交换机：

　　软件交换机提供了完整的灵活性：表的数量、表的配置和解析都是在软件的控制之下。编译器直接将mTag表图映射到交换机的表中。编译器使用表类型信息来限制表的宽度、长度和每张表的匹配准则（例如精确匹配，范围匹配或通配符匹配）。编译器也可能通过软件数据结构来优化三重匹配或者前缀匹配。

2.　内含RAM和TCAM的硬件交换机：

　　编译器可以配置哈希散列，使用RAM来对边缘交换机的mTag_table表执行有效的精确匹配。而核心层的mTag转发表是要匹配标签比特位的一个子集，它将被映射到TCAM中去执行匹配。

3.　支持并行的规则表的交换机：

　　编译器能够检测数据依赖，然后安排各个表是串行执行还是并行执行。在mTag例子中，mTag_table表和local_switching表可以并行执行直到设置mTag动作的执行。

4.　在流水线的末端才执行动作的交换机：

　　对于只在流水线的末端才执行动作的交换机。编译器可以告诉中间的步骤生成元数据，在最终的执行中使用。在mTag例子中，无论是mTag标签的添加还是移除，都能在元数据中表现出来。

5.　只能容纳少量表的交换机：

　　编译器可以将大量的P4表映射到较少量的物理表中。在mTag例子中，本地交换表可以与mTag表结合起来。当控制器在运行时安装了新的规则，编译器的规则翻译器可以将原本应写入两个P4表中的规则重新编写，生成在单个物理表中的规则。

# 第六章 总结

　　SDN的愿望是单个控制平面可以直接控制整个交换设备网络。OpenFlow通过提供单一的厂商无依赖的API来支持这个目标。尽管如此，目前的OpenFlow面向的是那些认识预定义的首部区域集合、使用小的预定义动作集来处理数据包的固定功能的交换机。控制平面不能够表达数据包应该如何被处理以最佳地匹配控制应用的需求。

　　我们所提出的，是向更灵活的交换设备迈进的一步。这些设备的功能在领域中是特定的，也可能是可变的。开发者决定转发平面如何处理数据包，同时不用担心底层的实现细节是否支持。编译器将一个命令程序转换成TDG表依赖图，这张图可以被映射到许多特定的目标交换设备上，包括优化了的硬件实现。

　　我们强调，这仅仅只是第一步，这是一个为OpenFlow 2.0而设计的草案协议，供大家讨论。在这个提案中，交换设备仍有几个方面有待定义（例如拥塞控制原语、排队策略、流量监控）。尽管如此，我们相信创造一门配置语言的这种方法，将会引领我们实现具有更强灵活性的未来交换设备，也将会释放软件定义网络的潜能。

# 参考文献

[1] C. Kozanitis, J. Huber, S. Singh, and G. Varghese, “Leaping multiple headers in a single bound: Wire-speed parsing using the Kangaroo system,” in IEEE INFOCOM, pp. 830–838, 2010.

[2] P. Bosshart, G. Gibb, H.-S. Kim, G. Varghese, N. McKeown, M. Izzard, F. Mujica, and M. Horowitz, “Forwarding metamorphosis: Fast programmable match-action processing in hardware for SDN,” in ACM SIGCOMM, 2013.

[3] “Intel Ethernet Switch Silicon FM6000.” http://www.intel.com/content/dam/www/public/us/en/documents/white-papers/ethernet-switchfm6000-sdn-paper.pdf.

[4] N. Yadav and D. Cohn, “OpenFlow Primitive Set.”http://goo.gl/6qwbg, July 2011.

[5] H. Song, “Protocol-oblivious forwarding: Unleash the power of SDN through a future-proof forwarding plane,” in SIGCOMM HotSDN Workshop, Aug. 2013.

[6] “Openflow forwarding abstractions working group charter.” http://goo.gl/TtLtw0, Apr. 2013.

[7] M. Raju, A. Wundsam, and M. Yu, “NOSIX: A lightweight portability layer for the SDN OS,” ACM SIGCOMM Computer Communications Review, 2014.

[8] V. Jeyakumar, M. Alizadeh, C. Kim, and D. Mazieres, “Tiny packet programs for low-latency network control and monitoring,” in ACM SIGCOMM HotNets Workshop, Nov. 2013.

[9] A. Sivaraman, K. Winstein, S. Subramanian, and H. Balakrishnan, “No silver bullet: Extending SDN to the data plane,” in ACM SIGCOMM HotNets Workshop, Nov. 2013.

[10] E. Kohler, R. Morris, B. Chen, J. Jannotti, and M. F. Kaashoek, “The Click modular router,” ACM Transactions on Computer Systems, vol. 18, pp. 263–297, Aug. 2000.

[11] “Multiprotocol Label Switching Charter.” http://datatracker.ietf.org/wg/mpls/charter/.

[12] R. Niranjan Mysore, A. Pamboris, N. Farrington, N. Huang, P. Miri, S. Radhakrishnan, V. Subramanya, and A. Vahdat, “PortLand: A scalable fault-tolerant layer 2 data center network fabric,” in ACM SIGCOMM, pp. 39–50, Aug. 2009.

[13] P. McCann and S. Chandra, “PacketTypes: Abstract specificationa of network protocol messages,” in ACM SIGCOMM, pp. 321–333, Aug. 2000.

[14] G. Back, “DataScript - A specification and scripting language for binary data,” in Generative Programming and Component Engineering, vol. 2487, pp. 66–77, Lecture Notes in Computer Science, 2002.

[15] K. Fisher and R. Gruber, “PADS: A domain specific language for processing ad hoc data,” in ACM Conference on Programming Language Design and Implementation, pp. 295–304, June 2005.

[16] G. Gibb, G. Varghese, M. Horowitz, and N. McKeown, “Design principles for packet parsers,” in ANCS, pp. 13–24, 2013.

[17] “Open vSwitch website.” http://www.openvswitch.org.

[18] D. Zhou, B. Fan, H. Lim, M. Kaminsky, and D. G. Andersen, “Scalable, high performance Ethernet forwarding with CuckooSwitch,” in CoNext, pp. 97–108, 2013.

[19] “EZChip 240-Gigabit Network Processor for Carrier Ethernet Applications.” http://www.ezchip.com/p_np5.htm.

[20] “Broadcom BCM56850 Series.” https://www.broadcom.com/products/Switching/Data-Center/BCM56850-Series.
