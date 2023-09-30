---
layout: default
date: 音乐发布站
title: 音乐发布
permalink: /music/
icon: glyphicon-play

excerpt: 电子国风伴轻舞，唯我繁星少女组！关注微博 @SING女团 @天高任毛飞_大毛
---

<div id="index" class="row">
  <div class="col-sm-9">

    <div class="post-area">
      <!-- small button -->
     <!--  <p class="pull-right visible-xs">
       <button>toggle</button>
     </p> -->
      <div class="post-list-header">
        Vocal
      </div>

      <div class="post-list-body">  
        <div class="all-posts" post-cate="All">
          {% for vocalPage in site.music reversed %}
              {% if vocalPage.vocalName %}
                <a class="post-list-item" href="{{ vocalPage.url | prepend: site.baseurl }}">
                  <h2>
                  {{ vocalPage.vocalName }}
                  </h2>
                  <span class="">{{ vocalPage.date | date: "%b %-d, %Y" }}</span>
                  <!-- {{ vocalPage.date | date: "%b %-d, %Y" }} -->
                </a>
              {% endif %}
          {% endfor %}
        </div>
      </div>
    </div>

    <div class="post-area" style="margin-top: 20px;">
      <div class="post-list-header">
        Keyboard
      </div>

      <div class="post-list-body">
        <div class="all-posts" post-cate="All">
          {% for kbPage in site.music reversed %}
              {% if kbPage.keyboardName %}
                <a class="post-list-item" href="{{ kbPage.url | prepend: site.baseurl }}">
                  <h2>
                  {{ kbPage.keyboardName }}
                  </h2>
                  <span class="">{{ kbPage.date | date: "%b %-d, %Y" }}</span>
                  <!-- {{ kbPage.date | date: "%b %-d, %Y" }} -->
                </a>
              {% endif %}
          {% endfor %}
        </div>
      </div>
    </div>

  </div>


  <div class="col-sm-3">

    <div class="shadow-corner-curl hidden-xs">

      <div class="categories-list-header" style=" text-align:center;">
        <a href="{{ site.myGithubLink }}/"><img alt="" class="avatar" height="230" src="{{ site.myPhoto }}" width="230" /></a>

        <h2 class="MyName">
          {{ site.myName }}
        </h2>

          <a class="University" href="http://www.bupt.edu.cn/">{{ site.chinaName }} - {{ site.BUPTname }}</a>
          <a class="email" href="mailto:{{ site.email }}">{{ site.email }}</a>
      </div>

      <div class="categories-list-header">
        最近更新时间：<br />{{ site.time }}
      </div>
    </div>
  </div>
</div>
