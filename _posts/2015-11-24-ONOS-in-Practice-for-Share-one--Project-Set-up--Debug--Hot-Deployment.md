---
layout: post
title: ONOS 实战分享（一）：项目建立、调试到热部署
date: 2015-11-24 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: 本文将在Distributed Core Tier，以开发一个控制器内的模块为例，带领大家从项目的建立，导入IDE，编译构建，热部署，在线调试，最后到热迭代，走过一个项目的开发流程。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/15197.html](http://www.sdnlab.com/15197.html)**

![Mao](/resources/picture/2015/11/1.png) <br />

<br />

　　以上是ONOS的架构图，相信大家已经熟记于心了 √

　　本文将在Distributed Core Tier，以开发一个控制器内的模块为例，带领大家从项目的建立，导入IDE，编译构建，热部署，在线调试，最后到热迭代，走过一个项目的开发流程。

　　对于实现模块具体功能的介绍内容，请阅读我的后续文章。本文尽量不介绍Maven及其pom、OSGI、Karaf的内容，这些不是ONOS特有的，但需要朋友们对它们是什么、有什么作用，有个大致的了解，所以请大家Google之。

　　文中将会随时插入一些我在实践中遇到的棘手问题，和实践中需要注意的points。

　　希望本文能够给ONOS的入门开发者朋友们一些启发 ^_^

　　

　　Here we go!

　　

## （0）Hello, ONOS!

　　我参考官方Wiki搭建了ONOS环境，在此附几张图，让大家快速了解一下本文介绍的系统环境基础。

　　本文采用官方Git中的master分支，1.4.0-SNAPSHOT版本，2015.11.04下载，1.3.0以及更新的临近版本应该都不会有问题。
（如有变动，本博文会跟进更新，请留意题目中的更新日期）

　　官方Wiki：[Installing and Running ONOS](https://wiki.onosproject.org/display/ONOS/Installing+and+Running+ONOS) <br /><br />

　　按照官方一步步做，我印象中就不会遇到什么卡壳的问题，除了Download一些Maven 库的时候，是比较拼网络的，如果出问题，也可以考虑改用一些国内的Maven镜像站，如阿里云的Maven镜像，祝大家顺利。

　　

　　Karaf、Maven：

![Mao](/resources/picture/2015/11/2.png) <br />

　　

　　ONOS：

　　为了Eclipse工程方便，目前放在workspace下，仅作为后文介绍的“路径”前提。
 
![Mao](/resources/picture/2015/11/3.png) <br />

　　

　　ONOS主目录：

　　（target目录在编译后才有）

![Mao](/resources/picture/2015/11/4.png) <br />

　　

　　ONOS apps目录：

　　运作在Distributed Core Tier的模块，多数都在这，我们将要一起开发的模块也在此。

　　（target目录在编译后才有）
 
![Mao](/resources/picture/2015/11/5.png) <br />

　　

## （1）项目建立

　　应该是从ONOS 1.3版本开始，官方提供了一个脚本，用于项目建立的便利，我先带大家一起来使用，文末再给大家看看内容。

![Mao](/resources/picture/2015/11/6.png) <br />

　　

　　就是这个脚本，让我们开始！

　　在某个不含pom.xml文件的目录下，执行onos-create-app，要等一段时间，才会出现命令行里的最后那一句：

![Mao](/resources/picture/2015/11/7.png) <br />

　　

　　这里我们输入试验使用的信息，依次如下：
 
![Mao](/resources/picture/2015/11/8.png) <br />

　　

　　这里有个我尚未理解的现象：

　　如果groupId不是以“org.onosproject”为前缀的；Version如果跟ONOS的版本1.4.0-SNAPSHOT不一样的。后续的编译完的部署会不太一样，后续“热部署”章节会告诉大家如何解决。

　　如果groupId不是以“org.onosproject”为前缀，解决后但仍不太理想，特别是当模块往复杂里做的时候。如果没有特殊需要的话，推荐大家按照这个前缀来。

　　

　　That’s good!

![Mao](/resources/picture/2015/11/9.png) <br />

　　

　　我们刚刚构建了一个这样的目录结构：

![Mao](/resources/picture/2015/11/10.png) <br />

　　

　　生成了三个文件：

> * pom.xml – Maven项目文件
> * AppComponent.java – 模块文件
> * AppComponentTest.java – Maven构建模块时，用于测试模块的文件
> 
> （自动生成的AppComponent.java可以删除，换成我们自己的文件就好，本文暂且使用它。）

　　AppComponentTest.java可以在构建模块时，通过参数 –DskipTests 跳过测试，我暂时还没有掌握怎么改写它，暂不改动，大家也可以予以删除。不过如果大家要开发作为正式使用的模块，还是要学习一下如何编写它比较好。

　　

　　推荐大家此时，把整个SDNLAB-Demo移动到onos/apps/目录下，最外层的SDNLAB-Demo文件夹删除，最后如下：

![Mao](/resources/picture/2015/11/11.png) <br />

　　

　　接下来，我们需要修改pom.xml文件：

　　如图，解除注释，输入我们想要的信息，如下：

> * 红箭头No.1，模块的基本信息
> * 红箭头No.2，模块的描述信息
> * 红箭头No.3，应用名和开发者组织名称

![Mao](/resources/picture/2015/11/12.png) <br />

　　

　　然后打开apps目录下其他任意一个模块的pom.xml文件，从中复制<parent>段的信息，贴到我们的pom里面来：

![Mao](/resources/picture/2015/11/13.png) <br />

　　

　　最后，打开apps目录下的pom，加入我们模块的信息，这样前后的从属关系就建立好了：

![Mao](/resources/picture/2015/11/14.png) <br />

　　

　　项目建立到此完成，感兴趣的朋友可以去瞧一瞧实现功能的AppComponent.java哦！

　　

## （2）导入IDE

　　JAVA开发需要导入一大堆的包，虽说我们应该记住一些常用的包名，但实际工程中还是让IDE来帮我们做这些繁琐的工作吧，Let's Go!

　　IntelliJ IDEA比Eclipse更方便、更智能、更流畅，推荐大家使用，本文详细介绍IDEA， Eclipse部分作为附录式展示。

> * 注：需要首先把整个ONOS源代码导入进IDE中
> * 注：为保持文章的连贯性，把ONOS导入IDEA的方法请见我博客中的另一篇文章：

====================ONOS导入IDEA====================

　　注：把ONOS导入Eclipse中，在此也不赘述了，参照官网Wiki：[Development Environment Setup](https://wiki.onosproject.org/display/ONOS/Development+Environment+Setup) <br /><br />

　　如果遇到问题，可以Google、Wiki或到ONOS群里交流哈，比如：454644351

　　

### 1. IDEA

　　

　　好的，不急着做，我们先来看看成功导入ONOS之后，大致是个什么样：

![Mao](/resources/picture/2015/11/15.png) <br />

　　

　　IDEA借用pom文件来维护整个“工程目录树”，我们不需要在IDEA中做任何的导入工作，只需要：

> 1. 把代码文件拷入ONOS目录，如apps中
> 2. 在apps和我们app的两个pom中，加入从属关系，即（1）中的步骤

　　

　　然后回到IDEA，就会发现我们的模块已经存在于目录树中了，so easy！

![Mao](/resources/picture/2015/11/16.png) <br />

　　

　　咱们的模块已经导入成功，右侧就是最简单的一个模块代码哦！如何开发模块的功能，可翻看我后续的文章，初步的了解可参考SDNLAB文章：[ONOS编程系列(一)之简单应用开发](http://www.sdnlab.com/10609.html) <br /><br />

　　

### 2. Eclipse

　　
 
![Mao](/resources/picture/2015/11/17.png) <br />

　　

　　感觉跟IDEA比起来，项目聚合得不是很好，让我们开始导入吧：

![Mao](/resources/picture/2015/11/18.png) <br />

![Mao](/resources/picture/2015/11/19.png) <br />

　　

## （3）编译构建项目

　　在这给大家介绍两种方式，Terminal方式、IDE方式，我推荐大家用Terminal方式，编译完直接就可以敲命令部署进ONOS。

###  1. Terminal方式：

　　在模块主目录下，执行：mvn clean install -DskipTests

> * Clean，清除旧的构建结果；
> * Install，构建新的模块；
> * -DskipTests，跳过构建完成后的测试步骤，debug阶段暂且跳过吧：

![Mao](/resources/picture/2015/11/20.png) <br />

![Mao](/resources/picture/2015/11/21.png) <br />

　　

### 2. IDE方式：

![Mao](/resources/picture/2015/11/22.png) <br />

　　

> ### 构建完成！我们刚才构建完以后，发生了哪些变化呢：
> 
> 1) 模块目录下多了target文件夹，.oar文件就是我们的ONOS应用模块文件：
> oar文件可单独、直接用于模块的远程热部署
> 
> ![Mao](/resources/picture/2015/11/23.png) <br />
> 
> 
> 2) 项目被安装到本地Maven仓库，信息同时加入仓库的repository.xml文件：
> 
> ![Mao](/resources/picture/2015/11/24.png) <br />
> 
> ![Mao](/resources/picture/2015/11/25.png) <br />
> 
> ![Mao](/resources/picture/2015/11/26.png) <br />
> 

　　

## （4）ONOS模块热部署

　　onos-karaf 启动ONOS，可以看到模块已经装载进ONOS了，但是没有启动。

　　By the way，我们模块名称是SDNLAB-Demo

![Mao](/resources/picture/2015/11/27.png) <br />

　　

> ### 这里有个疑问尚未解决：
>
> 　　如果version设置得跟当前ONOS的不一样，
>
> 　　即不是1.4.0-SNAPSHOT，那么这里将不会默认将模块从本地Maven库中装载进来，可能是因为在Karaf的配置文件中，onosproject只是写了1.4.0***的部分吧？
>
> 　　我跟踪了Karaf的启动过程，多次尝试改动，摸索了一段时间，还是没能弄清楚缘由，还请了解的朋友们指教，非常感谢！如下：
>
> ![Mao](/resources/picture/2015/11/28.png) <br />
>
> 　　而且在项目构建的时候，如果使用的是其他version，会额外下载相应版本的依赖文件，虽然下载不成功只是warning，模块也能工作，但不知道会有什么副作用。

　　

　　如果写好的模块要“热部署”到远端，或者是模块没有被默认装载，则命令没有任何回显，如下： 

![Mao](/resources/picture/2015/11/29.png) <br />

　　

　　进入oar文件所在目录，一条命令onos-app，完成远程安装模块：

![Mao](/resources/picture/2015/11/30.png) <br />

　　

　　可以看到，我们应用的全名是“org.onosproject.Mao.SDNLAB-Demo”，我们后续更新迭代、启动/停止模块都需要用到它。

　　

　　第二条命令，完成远程启动模块：
 
![Mao](/resources/picture/2015/11/31.png) <br />

　　

　　再次查看，可以发现我们的模块已经成功装载，并且启动！
 
![Mao](/resources/picture/2015/11/32.png) <br />

　　

## （5）ONOS在线调试

　　

　　^_^ 这是让我觉得很有趣的地方，原以为这样的大框架系统只能通过日志或命令行print来调试呢，这真是太棒了！

　　

　　用 onos-karaf debug 来启动ONOS，会开启5005远程调试端口：
 
![Mao](/resources/picture/2015/11/33.png) <br />

　　

　　启动 Eclipse或IDEA，IDEA会更方便，更清晰，但是IDEA的弊端是它的变量界面每次都会清屏再刷新，好在不用重新展开各项，大家用了就会理解。

　　

### 1. IDEA
 
　　配置远程调试，一张图搞定：
 
![Mao](/resources/picture/2015/11/34.png) <br />

　　

　　我们在模块加载入口函数activate()中设定断点，开始调试，如果没有安装或开启模块，可以：

![Mao](/resources/picture/2015/11/35.png) <br />

　　

　　如果模块已经是active，为了触发这个断点，我们将它关了再开一次。

![Mao](/resources/picture/2015/11/36.png) <br />

　　

　　看！Karaf console控制台线程正在执行我们的模块加载函数，ONOS已经卡住了。

![Mao](/resources/picture/2015/11/37.png) <br />

　　

　　ONOS的线程池也是美美的 ^_^

![Mao](/resources/picture/2015/11/38.png) <br />

　　

　　我们唯一的内部变量已显示，断点卡在了即将写日志的地方。

![Mao](/resources/picture/2015/11/39.png) <br />

　　

　　^_^ 小伙伴们，可以愉快地调试了哦！

　　

### 2. Eclipse

![Mao](/resources/picture/2015/11/40.png) <br />

![Mao](/resources/picture/2015/11/41.png) <br />

![Mao](/resources/picture/2015/11/42.png) <br />

![Mao](/resources/picture/2015/11/43.png) <br />

　　

## （6）ONOS模块热迭代

　　假设我们已经修改了模块的代码，现在准备上线调试或运行，为了展示方便和标识版本，首先，修改pom文件中的<description>、重新编译构建：

![Mao](/resources/picture/2015/11/44.png) <br />

　　

　　模块已经存在，这时候是不能install的：

![Mao](/resources/picture/2015/11/45.png) <br />

　　

　　这时候需要用上我们的应用名，用reinstall参数：

![Mao](/resources/picture/2015/11/46.png) <br />

　　

　　That’s Good!

![Mao](/resources/picture/2015/11/47.png) <br />

　　

## （7）思考 & 展示

### 1.我的疑惑：

　　整个开发过程似乎都不需对onos/feature/feature.xml文件进行修改，反而onos/apps里面的模块构建以后是存档在本地Maven仓库里的（~/.m2/repository），而且他们的装载也不依赖于onos源代码文件夹了。

　　于是我想找到Karaf是如何找到我们的模块的，我从onos-karaf入口开始，到onos-setup-karaf，再到karaf/bin/karaf，有点眼晕，没有找到什么线索。

　　另外只知道karaf/etc/org.apache.karaf.features.cfg有大仓库的位置信息，可是里头跟onos/feature/feature.xml是一样的，里头没有任何onos/apps中模块的信息。而且我尝试着在Maven库的~/.m2/repository.xml中删去模块信息，也没有用，Karaf照样能载入那个模块。

　　同时，编译后onos/feature/feature.xml文件也都被放到Maven仓库中了，整个onos似乎都被搬到Maven库中了，运行似乎都跟源码文件夹没有什么关系？

　　（除了入口脚本onos-karaf是被指定在源码文件夹中）

　　对于需要groupId以“org.onosproject”为前缀、Version如果跟ONOS的版本1.4.0-SNAPSHOT一样的情况，也是挺疑惑的，估计也跟Karaf寻找仓库、模块的方法有关。

　　但是如果version设置得不一样，会导致构建过程中下载其他版本的pom文件或库，可能存在问题的隐患，但如果不能灵活改变的话，版本号的意义何在呢，待探索……

　　以上是我关于本文的存疑之处，希望了解的朋友能给我一些指点，小毛我先谢谢大家了！

　　

### 2.说好的各种脚本秀

　　脚本位置：

![Mao](/resources/picture/2015/11/48.png) <br />

　　

　　onos-create-app，本质是使用了mvn的项目原型框架：

![Mao](/resources/picture/2015/11/49.png) <br />

　　

　　onos-app，本质是使用了REST API北向接口，这接口是不是很强大 ^_^ 

![Mao](/resources/picture/2015/11/50.png) <br />

　　

　　onos-karaf，ONOS启动脚本：先配置好karaf环境，再启动karaf本体：

![Mao](/resources/picture/2015/11/51.png) <br />

　　

　　onos-setup-karaf，配置环境，将默认装载的模块全部准备好，舞场后台Staging就位 ^_^
只给大家展示熟悉的部分好啦：

![Mao](/resources/picture/2015/11/52.png) <br />

　　

　　Karaf，大家感兴趣就去瞄两眼吧 ^_^

![Mao](/resources/picture/2015/11/53.png) <br />

　　

## （8）结语 & 感悟

　　ONOS和ODL，两个BOSS级的控制器/系统。原本我是从ODL入手的，可是对于ODL控制器内部的开发教程实在太少，或者应该说是难以寻到。

　　原本以为官方的Wiki应该是一扇不错的大门，后面应该有一条路灯明亮的小径，哪怕它再曲折幽深，我也无惧。

　　可惜ODL的Wiki给我的感觉是一个知识的大仓库，仓库入口附近还没有仓储名录，面对着找不到目录的wiki主页，我茫然了。虽然看完了 地球-某某 老师的一百多页的开发案例讲解PDF，但还是觉得头脑中的实践路线不清晰。直到那天看 明明姐@陈明明-北邮，在群里说wiki上已经有一些tutorial，我就马上去搜，发现了两三条对于开发入门不错的文章标题，于是火速将所有tutorial放进我的收藏夹 ^_^ 谢谢明明姐，美美哒！

　　最近实验室项目的关系，我投入到ONOS的学习中。ONOS让我有点惊喜，wiki左侧目录右侧内容，关键区域还有YouTube视频指点迷津。

　　ONOS对于开发入门的朋友还有三四篇经典的tutorial wiki文章，源代码也是分块清晰，代码结构更是简洁明了，各层之间的关系，层之间、模块之间如何交换信息都能清楚地在代码层面轻松寻到。一切都看起来规规矩矩，有章可循，很赞！

　　在这里也要感谢一下 北京石头 这位朋友，您在SDNLAB中的四篇入门分享文，是我的引路之石。

　　希望大家看完我的这篇文章，能对大家入门ONOS有一些帮助，如果确实如此，那将是我莫大的快乐，希望能与大家共同进步！

　　

　　北京，海淀 2015.11.24
