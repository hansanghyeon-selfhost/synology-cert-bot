Docker를 이용한 Let's encrypt 발급

Let's encrypt는 3개월마다 갱신을 해줘야 합니다.

Synology NAS(DSM)에서 Let's encrypt를 발급받는 방법중 대부분이 사용하는 DSM에 자체적으로 제어판-보안-인증서에서 발급받는 기능이 존해합니다.
하지만 정상적으로 발급받기 위해서는
- 방화벽개방
- 기존 인증서 정리
- 포트포워딩

조건이 까다롭습니다 그리고 에러가 발생해도 뭐때문인지 나오지 않는 것이 제일 문제라고 생각합니다.

이 때문에 docker를 활용하면 미리 설정하지 않아도 간단하게 인증서를 발급 받을 수 있습니다.

## 발급받기

폴더구조 설정

```
.
├── etc
└── var
```

해당 폴더구조를 설정

저는 해당폴더가 `/volume1/docker/ssl` 폴더에서 진행한다고 가정합겠습니다.

`issue.sh`

```sh
# 인증서 발급
docker run -it --rm --name certbot \
	-v '/volume1/docker/ssl/etc:/etc/letsencrypt' \
	-v '/volume1/docker/ssl/var:/var/lib/letsencrypt' \
	certbot/certbot certonly \
	-d '도메인주소' \
	-d '*.와일드도메인주소' \
	--manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory
```

위오 같이 `certbot/certbot` 도커이미지를 활용해서 발급 받습니다.

발급받으면서

```
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.xxxx.com with the following value:

a6cL5ZGCjdSPnpAJlo_XWTBUqZFvayNIdxqwnhnMa6E

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```

DNS에서 위와 같이 `_acme-challenge.xxxx.com` 도메인에 `TXT Type`으로 해당 값을 설정해줍니다.

정상적으로 DNS에 해당 도메인에 값이 설정되었는지 확인하는 방법은

```
dig +short -t txt _acme-challenge.도메인명
```

위 정보에 입력한 문자열이 나타나면 제대로 적용된 것입니다. 그러면 enter를 클릭해 다음으로 넘어갑니다.

그러면 `/etc/live/도메인명/인증서파일` 해당경로에 인증서들이 저장됩니다.

- `cert.pem`
- `chain.pem`
- `privkey.pem`
- `fullchain.pem`

## 인증서 적용하기

시놀로지(제어판-보안-인증서)에서 저장한 인증서파일은 `/usr/syno/etc/certificate/_archive`에 각각 랜덤한 이름을 가진 폴더로 저장되고 해당 정보는 `/usr/syno/etc/certificate/_archive/INFO` 파일에 저장됩니다.
그리고 이 인증서 중 기본 인증서는 `/usr/syno/etc/certificate/system/default`에 복사되는 구조입니다.

시스템에 직접적으로 인증서를 넣는 방법은 반영되지 않습니다.

일단 랜덤한 인증서 폴더를 만들기위해서 만을어 놓은 인증서 파일들을 다운로드 받습니다

DSM에서 제어판 - 보안 - 인증서 - 추가 - 인증서 가져오기

| 이름                     | 키              |
| ------------------------ | --------------- |
| 개인키                   | `privkey.pem`   |
| 인증서                   | `cert.pem`      |
| 중간 인증서              | `chain.pem`     |
| 인증서와 중간인증서 묶음 | `fullchain.pem` |

위와 같이 지정합니다.

SSH에 접속해서 `/usr/syno/etc/certificate/_archive` 이동해줍니다.
저장한 인증서가 어떤 폴더에 저장되었는지 `/usr/syno/etc/certificate/_archive/INFO` 파일에서 확인

해당 폴더로 이동
`/usr/syno/etc/certificate/_archive/랜덤폴더`

여기에 저장된 인증서 파일을 모두 삭제

그리고 Docker certbot/certbot 이미지로 만들어진 live 파일을 링크로 연결합니다.

```
ln -s /volume1/docker/ssl/etc/live/도메인/cert.pem /usr/syno/etc/certificate/_archive/4Fsmar/cert.pem
ln -s /volume1/docker/ssl/etc/live/도메인/chain.pem /usr/syno/etc/certificate/_archive/4Fsmar/chain.pem
ln -s /volume1/docker/ssl/etc/live/도메인/privkey.pem /usr/syno/etc/certificate/_archive/4Fsmar/privkey.pem
ln -s /volume1/docker/ssl/etc/live/도메인/fullchain.pem /usr/syno/etc/certificate/_archive/4Fsmar/fullchain.pem
```

그리고 다시 DSM에 인증서로 돌아가서 사용할 서비스에 인증서 등록

👏 인증서 등록까지 수고하셧습니다.

하지만 여기까지하면 3개월마다 인증서를 수동으로 갱신해야 합니다.

그러기엔 우리의 시간은 아깝고 기억해야하는 부담이 있죠 바로 갱신을 자동화합시다.


## 자동으로 갱신되게 설정하기

인증서 프로젝트파일에 `renew.sh`라 명하는 스크립트 파일을 생성합니다.

`renew.sh`

```sh
# 인증서 갱신
docker run -it --rm --name certbot \
	-v '/volume1/docker/ssl/etc:/etc/letsencrypt' \
	-v '/volume1/docker/ssl/var:/var/lib/letsencrypt' \
	certbot/certbot renew --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory

# 시놀로지 nginx 리로드
# synoservicectl --reload nginx  # DSM6.0
synosystemctl reload nginx  # DSM7.0
```

중간에 `cerbot/certbot renew` 이부분이 갱신하겠다는 명령어로 설정만 해주시면 됩니다.

DSM의 제어판 - 작업스케줄러 - 생성 - 예약된 작업 - 사용자 정의 스크립트

스케줄 설정하고 작업 설정에서

```
bash /volume1/docker/ssl/renew.sh
```

자동갱신 스크립트까지 모두 완료하였습니다.

👏👏👏
