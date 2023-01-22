#!/bin/sh

DIR=$(dirname $(readlink -f $0))
DOMAIN=720p.hyeon.pro
echo "시놀로지에 등록한 인증서폴더를 등록하세요 (ex: 4Fmars)"
read INFO_HASH 

if [ -z "$INFO_HASH" ]; then
	echo "ERROR: 입력하지 않았습니다"
else
	echo "입력한값: $INFO_HASH"
	echo "cert_bot에서 인증받은 인증서를 심볼릭링크로 synology의 인증서를 덮어씌웁니다"
fi

rm -rf /usr/syno/etc/certificate/_archive/$INFO_HASH/*
ln -s $DIR/.docker/etc/live/$DOMAIN/cert.pem /usr/syno/etc/certificate/_archive/$INFO_HASH/cert.pem
ln -s $DIR/.docker/etc/live/$DOMAIN/chain.pem /usr/syno/etc/certificate/_archive/$INFO_HASH/chain.pem
ln -s $DIR/.docker/etc/live/$DOMAIN/privkey.pem /usr/syno/etc/certificate/_archive/$INFO_HASH/privkey.pem
ln -s $DIR/.docker/etc/live/$DOMAIN/fullchain.pem /usr/syno/etc/certificate/_archive/$INFO_HASH/fullchain.pem
chmod 400 /usr/syno/etc/certificate/_archive/$INFO_HASH/
