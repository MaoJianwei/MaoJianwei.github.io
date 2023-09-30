---
layout: post
title: SDN：优雅的间歇性访问限制
date: 2015-07-05 14:00:00 +0800
comments: true
categories: SDN RYU
excerpt: 优雅的间歇性访问限制：设有一台PC机（Host1），一台Web服务器（Host2）提供简单的静态网页访问服务。通过RYU控制网络流，限制PC访问服务器的频率，如两次访问的间隔不能低于5秒。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/12381.html](http://www.sdnlab.com/12381.html)**

# 一、项目简介

#### 　 Github开源：

> [Mao Graceful Web Access Control](https://github.com/MaoJianwei/SDN_Scripts/tree/master/Mao_Graceful_Web_Access_Control)

#### 　 目的：

> 设有一台PC机（Host1），一台Web服务器（Host2）提供简单的静态网页访问服务。通过RYU控制网络流，限制PC访问服务器的频率，如两次访问的间隔不能低于5秒。

#### 　 应用场景：

> ① 为 付费用户 和 免费用户 提供差异化服务
>
> ② 小型站点、个人站点、未做优化站点的负载缓解
>
> ③ ……

　　在详细了解TCP三次握手、四次挥手、RST强制重置，以及HTTP包交互全程的基础上，本项目达成了以下特色：

> * 限制访问时，返回给PC友好的WEB页面提示，而不是仅仅通过流表把包丢弃，以及由此导致的PC用户浏览器持续等待、多次TCP重传、多次HTTP尝试。

# 二、关键技术分析


　　本项目中，由于TCP重传机制的特殊性，控制器不对握手和挥手等TCP控制交互阶段进行控制，只对HTTP报文进行控制。控制器伪装了服务器的角色，好似第三方劫持会话。

　　对于80目的端口的TCP控制交互报文，控制器通过packet-out让其顺利转发。

　　当正常访问时，控制器通过packet-out让HTTP请求顺利转发，同时下一条从服务器到PC的反向流表；

　　当限制访问时，控制器通过：
> ① 提取计算Seq、提取计算Ack、设置bits协议标志位、设置window_size来构造一个TCP报文； 
>
> ② 同时依照HTTP协议构造一个web页面数据包（访问限制提示页面）
>
> ③ 构造Ip包
>
> ④ 构造Ethernet帧


　　然后按照HTTP -> TCP -> IP -> Ethernet 的顺序层层封装，将其发回给PC，PC即可显示限制访问的提示页面。一般情况下还不算完，此时虽然PC浏览器退出了等待状态，但是PC、服务器双方的TCP连接仍然保持，仍在占用资源。

　　由此，我通过巧妙构造TCP协议字段和HTTP协议字段，利用TCP挥手阶段的RST机制，让PC端向服务器主动发起RST报文，随后PC端和服务器会各自强制断开连接。

　　到此，一次优雅的访问限制圆满结束，PC、服务器的资源都不被持续占用，用户也不用茫然地等待，同时能得到友好的提示！

　　具体细节，详见下方的各项解析，以及下文的实验演示中的截图。（可放大观看）

## （1）TCP的有趣细节

　　TCP这个孩子非常执着，无论是握手阶段、数据通信阶段，还是挥手阶段，只要没有收到ACK，就会以“翻番”的时间间隔去重发数据包，1、2、4、8、16、32秒……。

　　开发过程中，我观察到如果单纯以丢包作为限制手段，TCP会持续握手握上五分钟之久！并且会持续下去。平日里我们看到的TCP报告连接失败，可能是对方积极地使用RST给了我们失败的指示。
	
　　因此，如果单纯地丢包，会导致PC浏览器持续处于等待网页的状态，即使我们设置限制间隔为一分钟，但其实一分钟过后自动打开的网页，是属于“同一次”访问。

　　RST协议字段在我这个项目中，可谓是一个神器，它是一个TCP协议字段，会让通信双方各自强制关闭连接。RST常出现在连接本身出现严重差错、通信对端端口不可达、在已关闭的socket上收到数据等情况。

　　在这里，我们利用了“连接本身出现严重差错”这一条：

>　　在HTTP响应数据包中，我们给TCP设置一个错误的Ack和一个正确的Seq，使得PC发起HTTP Request的超时重传，此时RYU会再次响应带有错误Ack却有正确Seq的响应，这就导致了PC端发现连接出现严重差错，中断连接！

　　经我分析，由于RYU第一次的响应是正常的通信过程，所以PC重传的HTTP Request中，TCP Ack已经累积递增，然后RYU的第二次响应中，有正确的Seq，说明已经是收到了重传的HTTP Request，按理说它的TCP Ack应该累积递增，但是却没有，而仍然是我们设定的错误Ack。

　　这就产生了矛盾！

　　因此PC端就主动发起了RST连接中断，特插图如下： <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/1.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/2.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/3.png) <br /><br />


## （2）最精简的HTTP响应数据

　　之前我在C++下开发过一些Socket通信程序，根据我的积累，仅包含必要信息的最精简HTTP需要有如下协议信息，各信息之间用“\r\n”分隔，协议头与数据之间用“\r\n\r\n”分隔：

> ①　协议版本、响应状态码：HTTP/1.1 200 OK
> 
> ②　数据段长度：Content-Length: 257
> 
> ③　数据内容类型、编码：Content-Type: text/html; charset=utf-8

# 三、项目演示

## （1）组网

　　
　　【 Mininet 】 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/4.png)  <br />

![MYpicture](/resources/picture/2015/07/YouYa/5.png)  <br /><br />


　　【 RYU 】 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/6.png) <br /><br />

## （2）软件准备


　　【 Mininet 】角色：h1 客户端（wget、Firefox）、h2服务器（Python SimpleHTTPServer） <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/7.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/8.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/9-1.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/9-2.png) <br /><br />

　　【Wireshark】启动两个，分别监控：s1-eth1（h1）、s1-eth2（h2），并且仅显示TCP包 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/10.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/11.png) <br />

![MYpicture](/resources/picture/2015/07/YouYa/12.png) <br /><br />


## （3）访问过程


　　由于Firefox在发起HTTP请求时会同时建立两个TCP连接，所以我们先以wget来演示一次HTTP请求的最典型的收发包情况，再以Firefox来直观演示Web页面效果。


### 1. wget 正常访问 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/13.png) <br /><br />

### 2. wget 限制访问 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/14.png) <br /><br />

### 3. Firefox 正常访问 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/15.png) <br /><br />

### 4. Firefox 限制访问 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/16.png) <br /><br />

### 5. Firefox 正常访问、限制访问 Web 页面 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/17.png) <br /><br /><br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/18.png) <br /><br />

# 四、核心代码展示

### （1）代码结构 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/19.png) <br /><br />

### （2）构造HTTP限制访问Web包


> <br />　　**HTTP -> TCP -> IP -> Ethernet** <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/20.png) <br /><br />

### （3）控制器伪装发包 <br /><br />

![MYpicture](/resources/picture/2015/07/YouYa/21.png) <br /><br />

### （4）限制间隔计时


> * 19行：Self.oldT 在__init__中初始化
> * 86行：检查是否需要限制访问，此处设定访问间隔为5秒 <br />
　　　【同时对网络延迟造成的正常TCP重传，设定0.3秒的容许】
> * 205行：刷新最后一次访问成功的时间 <br />
　 　　time.time() 用于获取系统当前时间
>

 <br />
![MYpicture](/resources/picture/2015/07/YouYa/22.png) <br /><br />

# 五、项目心得
　　这个项目的开发真是历经坎坷，我也在其中悟到了很多课堂上没有涉及到的知识。

　　通过多网口同时抓包，然后加以细致的分析，从TCP的三次握手、四次挥手，到TCP的Seq、Ack在传信令、数据时的累加机制，再到TCP的bits协议标志位，以及RST 这个连接守护者。一星一点地细看发包流程，然后在脑海中翻阅之前积累的TCP反馈重传、累积确认、滑动窗口等机制，对流程进行细致的研究。

　　虽然过程中遇到了一些难以理解的收发流程，但是我始终相信TCP这个东西在互联网上跑了这么多年，不会说在通信交互的机制上有什么BUG，一定是流程中出了什么样的意外情况导致了异常的收发，甚至连接的RST中断。

　　细粒度地分析实际通信场景、bits协议标志位、Seq、Ack，一定能找到问题症结所在！

　　通过这个小项目，我算是对TCP的理解更加细致、深入、实际了！

　　对于上方PC端主动发起RST的原因，只是我利用已有的知识积累，进行分析和一点点猜想的结果，还希望老师、学长学姐、同学们能给予我一些指导，非常感谢！

　　这学期的SDN课程行至尾声，还真的是意犹未尽，在北邮能听到这么有前瞻性的课程，真是一大幸事，我想，我们也只有始终站在潮流前端，才能保持优秀，引领未来！
