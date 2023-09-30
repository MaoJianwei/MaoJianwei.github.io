---
layout: post
title: P4入门教程（1）：搭建开发和实验环境
date: 2017-09-26 19:00:00 +0800
comments: true
categories: SDN P4
excerpt: 数据平面可编程，最大化地释放了网络的灵活可编程能力，在Telemetry网络管控、协议扩展、带状态的流量处理等方面都有很大的潜力有待发掘。这确实是个好的Idea。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[https://www.sdnlab.com/19912.html](https://www.sdnlab.com/19912.html)**

　　这个月来，我观察到P4社区的活跃度不高。几个主要的Github库更新缓慢，issue交流也比较少，今年以来P4最活跃的mail list，P4-dev，每个月最多也只有100次左右的交流。国内的P4交流社群的情况同样如此。

　　数据平面可编程，最大化地释放了网络的灵活可编程能力，在Telemetry网络管控、协议扩展、带状态的流量处理等方面都有很大的潜力有待发掘。这确实是个好的Idea。因此，我打算结合自己的研究和实践经验，撰写P4入门的连载文章，希望能给准备入门的朋友一点启发，咱们多多交流。

　　[P4语言规范](https://p4lang.github.io/p4-spec/)，阅读过P4语言规范的朋友们应该知道，P4是一门对数据平面抽象的编程语言，同时也是数据平面相关的编程语言，即target-dependent，主要体现在具体的程序设计要依赖于Architecture Model中对设备能力的规定。

　　因此，P4的开发环境笔者认为可以粗略分为三种：

> * 第一种是商用开发环境，诸如Barefoot出品的Capilano™，专门为其自家设计的芯片Tofino而推出的一款IDE。
> * 第二种是面向FPGA等硬件运行条件的开发环境，这种情况下P4程序大致需要先使用前端编译器来编译生成一种中间表示文件，然后再使用后端编译器根据中间表示文件生成目标运行文件。中间表示文件即IR文件，类似介于C语言和汇编之间的链接文件。目标运行文件类似windows平台的exe文件，linux平台的可执行二进制文件，以及能直接加载/烧写入FPGA运行的文件。
> * 第三种是面向软件交换机的开发环境，这种环境对于接触过OpenFlow开发和Open vSwitch（OVS）的朋友应该很熟悉。这种情况下P4程序只需要经过一次编译过程，生成数据平面的JSON格式描述文件，最后在启动软件交换机时将JSON描述文件导入即可。

　　第三种环境比较适合科研院校等，适用于在工程项目前期快速进行理论概念验证、初步的方案可行性检验和原型设计等，或者进行科研学术目的的仿真实验。

　　本系列文章主要针对面向软件交换机的P4开发进行讲解，往后不再赘述。

## 一、梳理思路

　　在Github上，P4项目拆分成了多个仓库，搭建开始前，我们先来做个梳理。

　　正如前文所述，P4程序只需要经过一次编译过程，生成数据平面的JSON格式描述文件，最后在启动软件交换机时将JSON描述文件导入即可。

　　编译这一步，我们需要使用编译器p4c来完成，即Github上的[p4lang/p4c库](https://github.com/p4lang/p4c),运行这一步，我们需要使用软件交换机bmv2来完成，即Github上的[p4lang/behavioral-model库](https://github.com/p4lang/behavioral-model),需要说明的是，P4语言现在出了新的一版，即P4-16，与原来的版本P4-14，共用同一款编译器和软件交换机。

　　现在还没有特殊的社区版IDE或者IDE插件用于支持P4开发，因此我们自行选用习惯的文本编辑器编写程序即可，笔者比较推荐Sublime。

## 二、系统环境

　　本文使用Ubuntu 16.04 LTS，内核版本4.10.0-33-generic，应该影响不大。

## 三、安装p4c

　　虽然编译make执行时间很长，但是各条命令不推荐大家一次性粘贴去执行，以防中途步骤错误导致后续的步骤让故障扩散。

### （1）安装依赖库：

```xml
$ sudo apt-get install g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev pkg-config python python-scapy python-ipaddr tcpdump cmake
```

<br />

### （2）手工安装依赖库Protocol Buffers：

　　Ubuntu 16.10及以上版本可以使用apt-get直接安装。

```xml
$ sudo apt-get install autoconf automake libtool curl make g++ unzip
$ git clone https://github.com/google/protobuf.git
```

<br />

　　进入下载好的protobuf项目目录，再继续：

```xml
$ ./autogen.sh
$ ./configure
$ make
$ make check
$ sudo make install
$ sudo ldconfig
```

![protobuf_make_check](/resources/picture/2017/09/P4T1/protobufMakeCheck.png)

<br />

### （3）下载p4c源码及必须的一些子模块：

```xml
$ git clone --recursive https://github.com/p4lang/p4c.git
```

<br />

　　进入下载好的p4c项目目录，再继续：

```xml
$ mkdir build
$ cd build
$ cmake ..
$ make -j4
$ make -j4 check
$ sudo make install
```

<br />

　　其中make -j4 check 是为了运行单元测试，确认p4c能正常工作。

![p4c_make_check](/resources/picture/2017/09/P4T1/p4cMakeCheck.png)

<br />

## 四、安装bmv2

### （1）下载bmv2源码：

```xml
$ git clone https://github.com/p4lang/behavioral-model.git
```

　　进入下载好的bmv2项目目录，再继续。

<br />

### （2）运行脚本安装依赖库：

```xml
$ ./install_deps.sh
```

　　脚本里使用到sudo，因此会让我们输入一次密码。

<br />

### （3）编译

```xml
$ ./autogen.sh
$ ./configure
$ make
$ sudo make install
```

<br />

### （4）运行单元测试，确认bmv2能正常工作

```xml
$ make check
```

![bmv2_make_check](/resources/picture/2017/09/P4T1/bmv2MakeCheck.png)

<br />

　　如果p4c和bmv2的各个单元测试用例都正常通过，我们的开发和实验环境就搭建完成了！

　　细心的读者朋友可能会发现，本文的行文风格与笔者以往的有所不同，专注于核心内容的讲解，免去了情绪方面的表达，语言也更加精炼。这都源于李呈师兄对笔者一次有意无意的点拨。其实当写到make check的时候，笔者不禁想到自己实验时看到“test pass”时的场景，按耐着微微激动的心情，敲完了上一段末尾的感叹号。

<br />

## 五、参考资料

> [1] [笔者个人博客](http://www.maojianwei.com/)
> 
> [2] [Github库 - Bmv2](https://github.com/p4lang/behavioral-model)
> 
> [3] [Github库 - p4c](https://github.com/p4lang/p4c)
> 
> [4] [P4官网](http://p4.org/)
> 
> [5] [P4语言规范](https://p4lang.github.io/p4-spec/)
> 
> [6] [P4邮件列表](http://lists.p4.org/mailman/listinfo/)
> 
> [7] [Barefoot官网](https://www.barefootnetworks.com/technology/)
> 
> [8] [Github库 - ProtoBuf](https://github.com/google/protobuf/blob/master/src/README.md)
