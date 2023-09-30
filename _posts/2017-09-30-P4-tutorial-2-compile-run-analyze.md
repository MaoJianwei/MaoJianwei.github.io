---
layout: post
title: P4入门教程（2）：P4程序的编译、运行验证与分析
date: 2017-09-30 19:00:00 +0800
comments: true
categories: SDN P4
excerpt: 本文重点讲述编译P4程序、启动P4交换机的方法，并以这样一个小功能为例展示P4程序的运行：交换机只处理IPv4包，把收到的包打上三层MPLS标签，再从入端口把包发回去。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[https://www.sdnlab.com/19936.html](https://www.sdnlab.com/19936.html)**

　　在前面[《P4入门教程：搭建开发和实验环境》](http://www.maojianwei.com/2017/09/30/P4-tutorial-2-compile-run-analyze/)一文中，梳理了P4实验的大致流程。P4程序只需要经过一次编译过程，生成数据平面的JSON格式描述文件，最后在启动软件交换机时将JSON描述文件导入即可。现在我带领大家来实际操作一下。

　　本文重点讲述编译P4程序、启动P4交换机的方法，并以这样一个小功能为例展示P4程序的运行：

　　交换机只处理IPv4包，把收到的包打上三层MPLS标签，再从入端口把包发回去。

## 一、实验环境

　　如下图，配置好两台虚拟机VM1、VM2，Ubuntu 16.04 LTS系统。

　　VM1作为Switch交换机，绑定ens192和ens224两个网口到交换机上，分别作为1、2号网口。

　　VM2作为Host主机，唯一的网口ens160与VM1的ens192网口直连，即接在交换机1号端口上。

![topo](/resources/picture/2017/09/P4T2/topo.png)

## 二、P4程序的编译及运行

　　首先，在笔者的Github下载示例代码：[mao_push_three_labels_send_back.p4](https://github.com/MaoJianwei/P4-example-code)

### （1）编译

　　执行编译命令，由.p4代码文件生成.json描述文件：

```xml
$ p4c-bm2-ss --p4v 16 -o output.file ./mao_push_three_labels_send_back.p4
```

　　p4c-bm2-ss是p4c项目编译完后的产物之一，专门用于将P4程序编译生成bmv2使用的描述文件。使用不同的编译器将生成适用于不同平台的文件。

>　**--p4v 16** 指明程序是用P4-16版语言编写的；
> 
>　**-o output.file** 指明生成文件的位置和名字；

　　代码文件的位置和名字写在最后。

　　如果编译成功，命令行不会有任何显示。如果出现warning，可能是实例化的资源没有被使用，函数参数没有被使用等，最好做出修正，但生成的文件仍可以导入交换机运行。 

![compile](/resources/picture/2017/09/P4T2/compile.png)

<br />

### （2）运行

　　执行运行命令，启动一个交换机并导入JSON文件：

```xml
$ sudo simple_switch -L 'trace' --thrift-port 9090 --log-file ~/maoP4/mao.log --log-flush -i 1@ens192 -i 2@ens224 output.file
```

　　simple_switch是behavioral-model项目编译完后的产物之一，可用作基本的P4设备。此外还有simple_router等，可在详细了解它们的特点后选用。

> **-L 'trace'**，日志相关，设置哪个级别以上的日志应该输出。
> 
> **--log-file ~/maoP4/mao.log**，日志相关，设置将日志记录在文件中及文件的位置和名称。
> 
> **--log-flush**，日志相关，当日志记录在文件中时，每条日志产生后直接写盘，而不需要等到磁盘缓冲区满。
> 
> **-i 1@ens192**
> 
> 可选项，将系统中某个Interface作为某号端口绑定到交换机上，可以是物理网口，也可以是veth等。这里将虚拟机的ens192网卡作为交换机的1号网口。
> 
> **--thrift-port 9090**
> 
> 设置RPC服务的监听端口，每个交换机需要设置不同的端口。P4交换机使用Thrift库来实现RPC服务。控制面通过RPC向服务器下发配置、更改转发表、修改寄存器中的值等。目前也有使用gRPC库来实现，其与ONOS等控制器能更好更灵活地交互，有兴趣的朋友可以研究一下。
> 
> **output.file**，由p4c-bm2-ss生成的JSON描述文件。

　　成功运行后，命令行会打印少量初始化信息。

![run](/resources/picture/2017/09/P4T2/run.png)

<br />

### （3）控制

　　启动控制程序：


```xml
$ simple_switch_CLI --thrift-port 9090
```

> **simple_switch_CLI**
> 
> bmv2自带的一个控制脚本，对应于simple_switch，运行后会进入一个新的命令行。这里不推荐使用官方介绍的runtime_CLI.py脚本，因为它在组播组配置等方面有bug，会导致控制程序崩溃，而且它的功能也不如simple_switch_CLI丰富。
> 
> **--thrift-port**，指明某个交换机的RPC服务监听的端口。默认是9090。
> 
> **--thrift-ip**，指明某个交换机的IP，可以远程控制交换机。默认是本机。

　　启动后，控制程序会先从交换机获取它的JSON描述信息，用于命令内容的初始化，然后进入事件循环，等待我们输入命令。支持按Tab补全命令，可用命令一览：

![all_cmd](/resources/picture/2017/09/P4T2/allCmd.png)

　　简单的操作可以在RuntimeCmd敲入命令完成，我们也可以将多条命令写入一个文本文件，每条命令占一行，然后通过Linux输入重定向的方式，一次性将多条命令导入Runtime执行。假设多条命令保存在command.txt中，示例如下：

　　**show_ports** 和 **show_tables** 两条命令分别查询了交换机的端口信息和匹配表信息。

```xml
$ simple_switch_CLI --thrift-port 9090 < command.txt
```

![multi_show_cmd](/resources/picture/2017/09/P4T2/multiShowCmd.png)

<br />

## 三、验证展示

　　编译、运行 mao_push_three_labels_send_back.p4，启动控制程序：

```xml
$ p4c-bm2-ss --p4v 16 --p4runtime-file maoRuntime.file --p4runtime-format text -o output.file mao_push_three_labels_send_back.p4
$ sudo simple_switch -L 'trace' --thrift-port 9090 --log-file ~/maoP4/mao.log --log-flush -i 1@ens192 -i 2@ens224 output.file
$ simple_switch_CLI --thrift-port 9090
```

　　VM2作为主机，Ping同网段的一个未分配的IP，200.0.0.2，目的只是利用ping发ICMP包来产生IPv4流量。

　　为了让演示过程更加精炼，程序没有让交换机处理二层流量，这将导致ARP不能完成，因此首先在VM2上进行ARP静态设置，然后开始产生IPv4流量：

```xml
$ sudo arp –s 200.0.0.2 66:66:66:66:66:66
```

![arp](/resources/picture/2017/09/P4T2/arp.png)

<br />

　　这时在交换机1号口检测到注入的v4流量，此时因为交换机匹配表中没有内容，因此直接丢包。

![drop_pkt](/resources/picture/2017/09/P4T2/dropPkt.png)

<br />

　　在Runtime命令行中添加一条匹配表，让发往200.0.0.2的包先打上三层MPLS标签，标签值由外到内分别是333、666、999，然后从入端口发回去：

```xml
RuntimeCmd: table_add ip_map_mpls push_3_labels_and_send_back 200.0.0.2 => 333 666 999
```

　　图中可以看到：上方，长度为98字节的Ping-request包后面紧跟着一个长度为110的Ping-request包。下方，这个包在原来的Ethernet和IP之间加入了三层MPLS标签，而且标签值和顺序正确。另外，Exp、bos(S)、TTL值是程序中设定的，其中bos(S)遵循了MPLS标签栈规则。

![fwd_pkt](/resources/picture/2017/09/P4T2/fwdPkt.png)

<br />

　　到此，P4程序的编译、运行和验证就顺利结束了，希望能给朋友们一点启发。下一篇“P4入门教程”系列连载文章中，我们将利用本次演示中的P4程序，进行P4程序结构的简析，敬请期待！

## 参考资料

> [1] [示例代码库](https://github.com/MaoJianwei/P4-example-code)
>
> [2] 《MPLS Fundamentals》，Cisco Press
