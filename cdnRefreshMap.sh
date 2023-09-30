
if [ $# != 1 ]
then
    echo 'usage: ./cdnRefreshMap.sh "https://www.maojianwei.com"'
    exit 1
fi

DOMAIN=$1
IDENTIFY="."

rm ./cdnRefreshMapAll.txt
rm ./cdnRefreshMapFile.txt
rm ./cdnRefreshMapDir.txt
jekyll clean
echo "Mao: clean OK"

jekyll build
echo "Mao: build OK"

cd "./_site/"
ALL="../cdnRefreshMapAll.txt"
FILE="../cdnRefreshMapFile.txt"
DIR="../cdnRefreshMapDir.txt"

for i in $(find)
do
    LINK=${i:1}
    if [[ $LINK == *$IDENTIFY* ]]
    then
        echo ${DOMAIN}${LINK} >> ${ALL}
        echo -e '"'"${DOMAIN}${LINK}"'"'',' >> ${FILE}
    else
        echo -e ${DOMAIN}${LINK}'/' >> ${ALL}
        echo -e '"'"${DOMAIN}${LINK}/"'"'',' >> ${DIR}
    fi
done
echo "Mao: index OK"
cd "../"
