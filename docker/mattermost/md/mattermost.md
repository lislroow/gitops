#### .env

```
postgres_db=
postgres_user=
postgres_password=

mm_servicesettings_siteurl=https://
```

#### mattermost.sh


#### mattermost.yml


#### docs

##### 1) SMTP

- system admin 계정(최초 생성한 계정) 으로 로그인
- 좌측 상단 'System Console' > 'Notifications' 이동
- 아래 항목 입력

```
Enable Email Notifications: true
Notification Display Name: Mattermost
Notification From Address: myeonggu.kim@kakao.com
Support Email Address: myeonggu.kim@kakao.com
Notification Reply-To Address: myeonggu.kim@kakao.com
```

- 좌측 상단 'System Console' > 'SMTP' 이동
- 아래 항목 입력

```
SMTP Server: smtp.kakao.com
SMTP Server Port: 465
Enable SMTP Authentication: true
SMTP Server Username: myeonggu.kim
SMTP Server Password: (kakao 에서 생성)
# https://accounts.kakao.com/weblogin/account/security/two_step_verification/manage#appPassword
```


##### 2) Localization

- 한국어 변경

```
Default Server Language: 한국어(Alpha)
Default Client Language: 한국어(Alpha)
```

##### 3) let's encrypt

```
# 인증서 발급
docker run -it --rm --name certbot -p 80:80 \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/lib/letsencrypt:/var/lib/letsencrypt" \
    certbot/certbot certonly --standalone -d 'mm.mgkim.net'

# mattermost-nginx 에서 참조
mattermost-nginx:
  volumes:
    - ./mattermost/nginx/conf.d:/etc/nginx/conf.d:ro
    - ./mattermost/nginx/dhparams4096.pem:/dhparams4096.pem
    - ./mattermost/nginx/webroot:/usr/share/nginx/html
    - /etc/letsencrypt/live/mm.mgkim.net/fullchain.pem:/cert.pem:ro
    - /etc/letsencrypt/live/mm.mgkim.net/privkey.pem:/key.pem:ro
```
