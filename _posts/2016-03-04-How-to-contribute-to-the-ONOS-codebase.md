---
layout: post
title: 如何向ONOS社区贡献代码
date: 2016-03-04 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: 笔者所在的实验室BUPT FNL在2015年成为ONOS在国内的第一个高校成员，因而有幸参与ONOS相关的研究与开发工作，本文是我根据自己一次成功提交代码的经历为大家梳理出来的详细步骤，希望能够为大家参与社区的代码开发提供帮助。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/16146.html](http://www.sdnlab.com/16146.html)**

　　ONOS是业界首个面向运营商业务场景的开源SDN控制器平台，主要面向服务提供商和企业骨干网。由于ONOS是完全开源的项目且面向全球的开发者开放，对于项目的管理有一整套的工具和流程，这也给想为社区贡献代码的同学带来一定的学习成本，笔者所在的实验室BUPT FNL在2015年成为ONOS在国内的第一个高校成员，因而有幸参与ONOS相关的研究与开发工作，本文是我根据自己一次成功提交代码的经历为大家梳理出来的详细步骤，希望能够为大家参与社区的代码开发提供帮助。

<br />

![onos_668 400](/resources/picture/2016/03/contributeONOS/1-onos_668_400.png)

<br />

　　众所周知，ONOS的代码管理是一个完整的CI系统(Continuous integration持续集成)。使用Gerrit来做代码审核和Git管理，使用Jenkins来做代码构建和测试，使用Github来做仓库的镜像存储。

　　Jenkins是一个进行代码构建、测试、部署的自动化工具，在这里主要用于每次向Gerrit进行一次submit后，自动触发一次ONOS代码构建和测试，就像我们在本地修改完代码以后尝试mvn clean install一样，只不过在Jenkins中可以写一些脚本去强化这个过程。

　　关于CI系统的详细内容不是本文的重点，大家可以Google之。

　　**在Github中，我们如果想贡献代码，需要以下几步：**

> A. Fork
> 
> B. Modify
> 
> C. Pull request
> 
> D. Code review
> 
> E. Merge

　　**类似地，Gerrit则是：**

> A.Fork
> 
> B.Modify
> 
> C.Submit
> 
> D.Module-Owner's review
> 
> E.Amend
> 
> F.Jenkins's approval
> 
> G.Module-Owner's approval
> 
> H.Merge

　　那我们具体需要做些什么呢，下面以笔者的一次成功的代码贡献经历为例，为大家梳理一下步骤：

<br />

![ONOS-contribute-code-picture-1](/resources/picture/2016/03/contributeONOS/2-ONOS-contribute-code-picture-1.png)

<br />

# 0.Register

　　在官网[onosproject.org](http://onosproject.org/register/)上注册一个ONOS账号。

　　在Gerrit上的提交是自动与Github同步的，按照ONOS的说法，Github只是作为一个镜像，仅供Clone，不接受Pull Request。

> 注：同步到Github后，会显示为我们个人Github账号的一次commit信息。笔者暂时不知道两边的账号是如何匹配对应上的，暂且让注册的用户名和邮箱跟Github账号的一致吧。

# 1.Git clone

　　ONOS Gerrit：[https://gerrit.onosproject.org](https://gerrit.onosproject.org)

　　下载ONOS的源码：

<br />

![ONOS-contribute-code-picture-2](/resources/picture/2016/03/contributeONOS/3-ONOS-contribute-code-picture-2.png)

<br />

# 2.Git checkout

　　创建一个新的分支，在新分支上做代码修改，相当于fork：

<br />

```

$ git checkout -b Improve-fwd-cfg-loading

```

<br />

# 3.Make changes to the code

　　使用各种IDE工具修改代码，注意一定要符合ONOS的代码风格要求，即CheckStyle.

　　修改和调试完后，使用mvn clean install尝试完整构建一次ONOS，显示全部SUCCESS以后，再使用mvn clean做一次清理，只留下源码，删去构建出的target内容

# 4.Sync the branch with updated master

　　在我们修改代码的时候，ONOS源码也在不断更新之中，我们在提交自己的代码之前，首先要让本地的ONOS源码与仓库里的保持一致，也即同步master分支上的所有new commits. 如果有merge conflict，则需要我们做出相应修正。

<br />

```

$ git checkout master
$ git pull --ff-only origin master
$ git checkout Improve-fwd-cfg-loading
$ git rebase -i master

```

<br />

# 5.Submit our contribution

　　我们提交上去的分支，在正式被Merge之前，要经过诸位代码审核者Reviewers的评论comment、许可确认Code-Review +1/-1，并且我们还要根据他们给出的修改意见去修正amend代码。

　　每一次修正和提交，都被记录成一次Patch Set，并且每次都需要经过Jenkins去完整地构建和测试代码，只有当它给出了Verified +1的结果，代码的审核流程才会继续下去。

　　提交我们的修改，这就相当于Github的pull request：

<br />

```

$ git review

```

<br />

> 注：需要git review这个命令，这不是git标配，我们可从网上下载安装文件，也可通过pip安装 *git-review*

　　然后即可看到我们的分支类似地出现在此处，ALL → Open

<br />

![ONOS-contribute-code-picture-3](/resources/picture/2016/03/contributeONOS/4-ONOS-contribute-code-picture-3.png)

<br />

　　点进我们提交的分支，如下是Jenkins构建的结果，这也将在上图的右下角“V”(Verified)中标示。

<br />

![ONOS-contribute-code-picture-4](/resources/picture/2016/03/contributeONOS/5-ONOS-contribute-code-picture-4.png)

<br />

# 6.Reply reviewer’s comment

　　在我们提交之后，Reviewer会对我们的代码提出问题、作出评论，我们可以进入Patch Set的评论页面，进行回复，如下图：

<br />

![ONOS-contribute-code-picture-5](/resources/picture/2016/03/contributeONOS/6-ONOS-contribute-code-picture-5.png)

<br />

![ONOS-contribute-code-picture-6](/resources/picture/2016/03/contributeONOS/7-ONOS-contribute-code-picture-6.png)

<br />

# 7.Amend our submission

　　在Reviewer作出了修改意见后，我们需要切换回我们的分支去做修正，首先要在上图的网址中找到我们submission的编号（上图中是7677）接下来简单的几步如下：

<br />

```

$ git review -d 7677

// TODO - 在IDE中修正我们的代码

$ git add [modified files]
$ git commit --amend
$ git review –R	//提交此次修正，成为一个新的Patch Set

```

<br />

![ONOS-contribute-code-picture-7](/resources/picture/2016/03/contributeONOS/8-ONOS-contribute-code-picture-7.png)

<br />

# 8.Reviewers approve and merge

　　当ONOS的Module Owner (诸位Reviewer之一) 审核并许可代码之后，将由这位Owner进行Merge操作，我们的此次代码贡献也就完成了！

<br />

![ONOS-contribute-code-picture-8](/resources/picture/2016/03/contributeONOS/9-ONOS-contribute-code-picture-8.png)

<br />

# 9.后记

　　按照以上8个步骤即可成功向ONOS社区贡献代码，如果在此过程中遇到问题还可以通过下面两种方式进行沟通和协作：

> A. 可以通过[ONOS的邮件列表](https://wiki.onosproject.org/display/ONOS/Mailing+Lists)，参与开发者的讨论和协作。
> 
> B. 也可以利用[ONOS的Jira工具](https://jira.onosproject.org)，管理我们提交的分支。
