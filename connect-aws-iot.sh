#!/usr/bin/env bash

#----------------------------------------------------------
# 引数があるか確認
#----------------------------------------------------------
if [ "${1}" = "" ]
then
    echo -e "Error:no argument.  \nex) connect-aws-iot.sh <thing name>"
    exit
fi

#----------------------------------------------------------
# 変数設定
#----------------------------------------------------------
cd `dirname ${0}`

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
#  AWS IoTの設定:証明書と鍵がないとき作成
#----------------------------------------------------------
if [ ! -e ${CERTIFICATE_PEM} ] || [ ! -e ${PRIVATE_KEY} ] || [ ! -e ${PUBLIC_KEY} ]; then
    
    # {thing name}-policy としてのIAM Policyを作成
    aws iot create-policy --policy-name ${1}-policy --policy-document '{"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": "iot:*","Resource": "*"}]}' > /dev/null 2>&1
    
    # thing 作成
    aws iot create-thing --thing-name ${1} > /dev/null 2>&1
    
    # 証明書と鍵を作成
    ARN_OF_CERTIFICATE=`aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile ${CERTIFICATE_PEM} --private-key-outfile ${PRIVATE_KEY} --public-key-outfile ${PUBLIC_KEY} --query "certificateArn"`
    echo ${ARN_OF_CERTIFICATE}
    
    # Policyと証明書を紐付け
    eval aws iot attach-principal-policy --policy-name ${1}-policy --principal ${ARN_OF_CERTIFICATE}
    
    # Thingと証明書を紐付け
    eval aws iot attach-thing-principal  --thing-name ${1} --principal ${ARN_OF_CERTIFICATE}
fi


#----------------------------------------------------------
#  AWS IoTのエンドポイント取得
#----------------------------------------------------------
ENDPOINT=`aws iot describe-endpoint --query "endpointAddress"`


#----------------------------------------------------------
#  トピック「topic/test」にPublish
#----------------------------------------------------------
CMD="mosquitto_pub --cafile ${ROOT_CA_PEM} --cert ${CERTIFICATE_PEM} --key ${PRIVATE_KEY} -h ${ENDPOINT} -p 8883 -q 1 -d -t topic/test -i ${1}-id -m '{\"key\": \"hello world from ThingName:${1}\"}'"
eval ${CMD}
