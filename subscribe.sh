#!/usr/bin/env bash

#----------------------------------------------------------
# 引数があるか確認
#----------------------------------------------------------
if [ "${1}" = "" ] || [ "${2}" = "" ]; then
    echo -e "Error:no argument.  \nex) subscribe.sh <thing name> <topic>"
    exit
fi

#----------------------------------------------------------
# 変数設定
#----------------------------------------------------------
cd $(dirname ${0})

readonly BASE_DIR='.'

readonly CERTIFICATE_PEM=${BASE_DIR}/cert-${1}.crt
readonly PRIVATE_KEY=${BASE_DIR}/private-${1}.key
readonly PUBLIC_KEY=${BASE_DIR}/public-${1}.key

readonly ROOT_CA_PEM=${BASE_DIR}/rootCA.pem
readonly ROOT_CA_DL_LINK='https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem'

#----------------------------------------------------------
#  root CA 証明書を確認:ないとき取得
#----------------------------------------------------------
if [ ! -e ${ROOT_CA_PEM} ]; then
    wget ${ROOT_CA_DL_LINK} -O ${ROOT_CA_PEM} > /dev/null 2>&1
fi

#----------------------------------------------------------
#  AWS IoTのエンドポイント取得
#----------------------------------------------------------
ENDPOINT=`aws iot describe-endpoint --endpoint-type iot:Data --query "endpointAddress"`


#----------------------------------------------------------
#  トピック「topic/test」にSubscribe
#----------------------------------------------------------
eval mosquitto_sub --cafile ${ROOT_CA_PEM} --cert ${CERTIFICATE_PEM} --key ${PRIVATE_KEY} -h ${ENDPOINT} -p 8883 -q 1 -d -t ${2} -i ${1}-id

