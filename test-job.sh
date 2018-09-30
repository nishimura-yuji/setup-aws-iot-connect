#!/usr/bin/env bash

#----------------------------------------------------------
# 引数があるか確認
#----------------------------------------------------------
# if [ "${1}" = "" ] || [ "${2}" = "" ]; then
#     echo -e "Error:no argument.  \nex) test-job.sh <job name> <target>"
#     exit
# fi

#----------------------------------------------------------
# jobがあるか確認:あれば削除
#----------------------------------------------------------

aws iot describe-job --job-id test > /dev/null

if test $? = 0; then
    aws iot delete-job --job-id test --force
fi

echo "delete start"
#----------------------------------------------------------
# jobがなくなるまでまつ
#----------------------------------------------------------

while True
do
    aws iot describe-job --job-id test > /dev/null 2>&1
    #breakへの糸口
    if test $? -ne 0; then
        break
    fi
    sleep 5
    echo "loop"
done

echo "delete finish"
#----------------------------------------------------------
# jobを作成
#----------------------------------------------------------
echo "job create"
aws iot create-job \
--job-id test \
--targets "arn:aws:iot:ap-northeast-1:438704618616:thing/test2" \
--document-source https://s3-ap-northeast-1.amazonaws.com/iot-job/job2.json \
--presigned-url-config roleArn=arn:aws:iam::438704618616:role/service-role/iot-raspberrypi,expiresInSec=300

#----------------------------------------------------------
# jobを削除
#----------------------------------------------------------

# aws iot delete-job --job-id test > /dev/null 2>&1
