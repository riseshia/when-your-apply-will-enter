#!/bin/bash

echo "Downloading data from e-Stat API..."
curl -s -X GET "http://api.e-stat.go.jp/rest/3.0/app/getSimpleStatsData?cdCat01=102000%2C103000%2C300000%2C301000%2C302000%2C305000&cdCat02=60&cdCat03=101170&appId=${APPLICATION_ID}&lang=J&statsDataId=0003449073&metaGetFlg=Y&cntGetFlg=N&explanationGetFlg=Y&annotationGetFlg=Y&sectionHeaderFlg=1&replaceSpChars=0" -o data.csv

echo "Converting data to JSON..."
bundle exec ruby convert-to-json.rb
rm data.csv
