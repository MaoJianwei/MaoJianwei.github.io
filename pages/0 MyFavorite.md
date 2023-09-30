---
layout: default
date: 收藏资料
title: 收藏资料
permalink: /MaoFavorite/
icon: glyphicon-star

excerpt: 电子国风伴轻舞，唯我繁星少女组！关注微博 @SING女团 @天高任毛飞_大毛
---

<div id="index" class="row">
  <div class="col-sm-9" id="MaoFavor">

    <div class="post-area">
      <div class="post-list-header">
        本页是动态页面，可能加载较慢...
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


<script type="text/javascript">
    $.ajax({
        url:"{{ site.url }}/resources/Dynamic/MyFavorite.json",
        // url: "http://192.168.1.101:4000/resources/Dynamic/MyFavorite.json",
        type: "GET",
        success: function (data) {

            var MaoFavor = document.getElementById("MaoFavor")
            var content = ""
            var first = 1

            for (var category in data) {
                if (1 == first) {
                    content += "<div class=\"post-area\"><div class=\"post-list-header\">" + category + "</div>" +
                        "<div class=\"post-list-body\"><div class=\"all-posts\" post-cate=\"All\">"
                    first = 0
                } else {
                    content += "<div class=\"post-area\" style=\"margin-top:20px\"><div class=\"post-list-header\">" + category + "</div>" +
                        "<div class=\"post-list-body\"><div class=\"all-posts\" post-cate=\"All\">"
                }

                var favors = data[category]
                for (var i = 0; i < favors.length; i++) {
                    content +=
                        "<a class=\"post-list-item\" href=\"" + favors[i]["link"] + "\">" +
                        "<h2>" + favors[i]["title"] + "</h2>" +
                        "<div><span class=\"\">" + favors[i]["time"] + "</span>" +
                        "<span class=\"\" style=\"float:right\">" + favors[i]["subtitle"] + "</span></div>" +
                        "</a>"
                }

                content += "</div></div></div>"
            }
            MaoFavor.innerHTML = content
        }
    });
</script>
