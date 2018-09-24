#!/usr/bin/env bash

#----------------------------------------------------------
# 引数があるか確認
#----------------------------------------------------------
if [ "${1}" = "" ]; then
    echo -e "Error:no argument.  \nex) setup-connect-aws-iot.sh <thing name>"
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

#----------------------------------------------------------
# ローカルファイル削除
#----------------------------------------------------------
rm -f ${CERTIFICATE_PEM} ${PRIVATE_KEY} ${PRIVATE_KEY}

#----------------------------------------------------------
# AWS IoTのリソース削除
#----------------------------------------------------------

# 証明書ARNを取得
CERTIFICATE_ARN=$(aws iot list-thing-principals --thing-name ${1} --query 'principals[0]')

# 証明書デタッチ
eval aws iot detach-thing-principal --thing-name ${1} --principal ${CERTIFICATE_ARN}

# ポリシーデタッチ
eval aws iot detach-policy --policy-name ${1}-policy --target ${CERTIFICATE_ARN}

# 証明書ID取得
get-certificate-id() {
    eval aws iot list-certificates --query 'certificates[?certificateArn==\`${CERTIFICATE_ARN}\`][certificateId]' --output text
}

# 証明書無効化
get-certificate-id | xargs aws iot update-certificate --new-status INACTIVE --certificate-id

# 証明書削除
get-certificate-id | xargs aws iot delete-certificate --certificate-id

# ポリシー削除
aws iot delete-policy --policy-name ${1}-policy

# Thing削除
aws iot delete-thing --thing-name ${1}
