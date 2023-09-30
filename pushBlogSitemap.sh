
######
# Before using,
# obtain Rest API & token from https://ziyuan.baidu.com/linksubmit/index - Baidu Zhanzhang
######

fileDomain="www.maojianwei.com"
sitemap="https://www.maojianwei.com/sitemap.xml"
pushFile="/home/mao/BaiduPush.txt"

while true
do
    rm -f ${pushFile}

    for line in $(curl -s ${sitemap})
    do
        if [[ ${line} =~ "<loc>" ]]
        then
            page=${line#*<loc>}
            page=${page%%</loc>*}
            echo ${page} >> ${pushFile}
        fi
    done

    # Mao: obtain token first!
    pushResult=$(curl -s -H 'Content-Type:text/plain' --data-binary @${pushFile} "http://data.zz.baidu.com/urls?site=www.maojianwei.com&token=&type=original")

    DATE=$(date +"%Y-%m-%d")
    TIME=$(date +"%H:%M:%S")

    #echo ${DATE}"_"${TIME}","${pushResult} >> /home/mao/pushSitemap_log/${fileDomain}_${DATE}.csv
    #echo ${DATE}"_"${TIME}","${pushResult} >> /home/mao/NFS/pushSitemap_log/${fileDomain}_${DATE}.csv
    echo ${DATE}"_"${TIME}","${pushResult}

    # sleep 1
    # curl -H 'Content-Type:text/plain' --data-binary @${pushFile} "http://data.zz.baidu.com/update?site=www.maojianwei.com&token="

    sleep 30
done
