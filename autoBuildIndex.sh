rm MaoBlog.tar.gz

./cdnRefreshMap.sh "https://www.maojianwei.com"

cp ./cdnRefreshMapAll.txt ./_site/
cp ./cdnRefreshMapFile.txt ./_site/
cp ./cdnRefreshMapDir.txt ./_site/

cp ./_site/sitemap.xml ./


rm ./_site/autoBuildIndex.sh
rm ./_site/CNAME
rm ./_site/cdnRefreshMap.sh
rm ./_site/migrateReadme.txt
rm ./_site/pushBlogSitemap.sh
echo "Mao: prepare _site OK"

tar -zcvf MaoBlog.tar.gz ./_site/
echo "Mao: release MaoBlog OK"
