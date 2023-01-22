#!/bin/bash

DIR=$(dirname $(readlink -f $0))

echo "이 스크립트는 synosystemctl 명령어의 권한이있어야해서 sudo로 진행해야합니다."
user_input="Y"
read -p "is sudo? [Y/n]" input
user_input=${input:-$user_input}

if ! [ "$user_input" = "Y" ]; then
	exit
fi

# 인증서 갱신
docker run -it --rm --name certbot \
	-v "$DIR/.docker/etc:/etc/letsencrypt" \
	-v "$DIR/.docker/var:/var/lib/letsencrypt" \
	certbot/certbot renew --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory

# 시놀로지 nginx 리로드
synosystemctl reload nginx

echo "인증서 갱신완료"
