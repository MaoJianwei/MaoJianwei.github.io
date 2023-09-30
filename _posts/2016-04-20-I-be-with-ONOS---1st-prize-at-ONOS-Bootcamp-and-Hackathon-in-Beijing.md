---
layout: post
title: 我和ONOS酱：ONOS全球首届集训营冠军团队赛后分享
date: 2016-04-20 19:00:00 +0800
comments: true
categories: SDN ONOS
excerpt: 很荣幸能够在老师的带领下，参加首届ONOS集训Hackathon，两天的讲授加两天的比赛，让我对ONOS的核心有了更深入的理解，对ONOS的发展现状有了更多的了解。
---

> **作者简介：{{ site.Resume }}**
> 
> **研究方向：{{ site.Major }}**
> 
> **SDNLAB 文章发表：[http://www.sdnlab.com/16595.html](http://www.sdnlab.com/16595.html)**

　　很荣幸能够在老师的带领下，参加首届ONOS集训Hackathon，两天的讲授加两天的比赛，让我对ONOS的核心有了更深入的理解，对ONOS的发展现状有了更多的了解。

　　我们的项目[ONOS_OVS_Manager_Bootcamp2016](https://github.com/MaoJianwei/ONOS_OVS_Manager_Bootcamp2016)在 Github开源，希望与大家交流学习。

<br />

![IMG_20160416_155512_720](/resources/picture/2016/04/onosBootcamp/0-IMG_20160416_155512_720.jpg)

<br />

　　一开始，我们聆听了Guru先生对ONOS未来的展望。接着青春活力的神秘班主任闪亮登场，带领我们做了一些相互熟络的小游戏之后，开始了抽签分组。

　　分组过后，紧张的培训就此开始。首先，David向我们介绍了ONOS的背景和最新进展，进行Hackathon的动员，然后Madan为我们剖析了ONOS的架构和集群机制。稍后，Hongtao讲解了Northbound，Satish讲解了Southbound。第一天，算是把ONOS从上到下、从里到外地琢磨了一遍。

　　第二天，重量级的内容开始了，上午Cas Majd和Chang Cao讲解了SDN-IP、IPRAN、CORD三大应用场景在ONOS中的应用模块；下午Madan为我们讲解和演示了ONOS的分布式能力和在其上的分布式应用开发。That’s amazing! 可惜的是，我在这天上午被学校抽中参加本科毕业设计的中期答辩，错过了半天的精彩。但我没有就此落下，晚上回到学校以后，先是跟着我的同伴复习下一天ONOS认证考试的内容，十一点半回到宿舍，拿着主办方发放的资料，琢磨着这几个案例，挑灯夜读到了一点钟方才睡下。

　　第三天，认证考试对我来说是今天的重头戏，算是人生中的第一份资格认证吧，务必要拿下，考题还是很开放的。十点半结束了考试，全员进入了紧张的Hackathon阶段，从“创新点比较好找”的角度考虑，我们组果断达成一致，选了看似能让我们最High的第七题。

　　任务分工、找创新点、Project Design、Coding & Debug、Check Style、Prepare Presentation，Github、IDEA、Visio通通调动起来，磕磕碰碰做到凌晨五点半，终于Push the Code，Have a sleep。期间遇到KARAF的两个大坑，多亏有Henry、邓晓涛同学和其他伙伴们的帮助，才顺利地从坑里爬出来，当时好像是凌晨两点半。

　　第四天，Show Time！我们是第四组，展示顺序不太靠前。展示分为对ON.Lab专家的技术展示，以及对全体营员的作品展示。我负责前者，展示前，我把项目的创新点、设计的亮点以及实现的精要之处用英文写了份简稿，然而尽管如此，展示时还是比较紧张，还好满满的干货还是博得专家们的一笑。全员展示结束之后，小组的其他伙伴提醒我，好像只有我讲完他们有在鼓了掌。Is it the truth? Unbelievable! 对了，专家们只问了我做的时候有没有遇到什么问题，I say I find a bug here in ONOS.

　　到了下午，激动人心的颁奖时刻来到了，然而我心里想的主要还是前一天考的认证有没有考下来，心里还是比较平静，哈哈。首先，华为的项目Leader和ON.Lab的David依次做了比赛总结，然后由Madan来对我们的作品做总体评价。虽然熬了一个通宵自己已经不太能跟上Madan讲话的节奏了，但是他讲话时经常对着我看，也是打破了我心里的平静。

　　Finally，David announce the prize，Group 2！Group 7！Group…………4！
激动，拥抱，合影！

<br />

![ONOS-Hackathon-figure-1](/resources/picture/2016/04/onosBootcamp/1-ONOS-Hackathon-figure-1.jpg)

<br />

　　于我而言，这次在知识上的最大收获主要有以下几点：

　　1. 集群角色切换：Failover、Load Balance、Log Timestamp

　　2. 集群数据同步：Raft-Copycat、State Machine、Log Replication、2 Phase Commit、Partition、Strong/Eventually Consistency

　　3. 理解了Switch Pipeline，在比赛中进行了开发和验证

　　4. 学习了SDN-IP、CORD这些典型的应用场景，以及ONOS针对这些场景的App应用，拓宽了我的眼界

　　5. ONOS分布式App的开发要点

　　这次的收获颇丰，我希望最近或者等五月忙完了毕设之后，能好好地写几篇文章，深入学习下去，做一些总结。

　　此外，我还收获了一次很好的团队合作经历。我们在比赛中做的项目是OVS Manager。从OVS switch的创建、删除、分类和罗列，到Pipeline的设计，再到流量目标的下发，每一步对我们来说都是新的实践。出点子、做演讲、设计开发，分工细致，讨论热烈，与其他组的朋友们互帮互助，大家都非常开心。我们最终幸运地获得了一等奖的好成绩，感谢我们Group 4的大伙伴们，以及一同走过四天一晚集训之路的同学们！

<br />

![ONOS-Hackathon-figure-2](/resources/picture/2016/04/onosBootcamp/2-ONOS-Hackathon-figure-2.jpg)

<br />

　　最后，要特别感谢ON.Lab的大牛讲师们，David，Madan，and other great teachers！

　　还要感谢来自华为的朋友们为我们提供了这次绝佳的培训机会，积极耐心地为我们答疑解惑，跟我们一起解决KARAF运行上的疑难杂症，在交流中拓宽了我们的视野，也让我们发现了技术的新大陆，希望以后还能有机会一起合作！
