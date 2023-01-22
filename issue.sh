#!/bin/sh

DIR=$(dirname $(readlink -f $0))

docker run -it --rm --name certbot \
	-v "$DIR/.docker/etc:/etc/letsencrypt" \
	-v "$DIR/.docker/var:/var/lib/letsencrypt" \
	certbot/certbot certonly \
	-d "720p.hyeon.pro" \
	-d "*.720p.hyeon.pro" \
	--manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory
