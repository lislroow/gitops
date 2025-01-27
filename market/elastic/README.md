

- env 파일(elastic.env)은 elastic.yml 에 모두 할당함

- elastic 8 은 kernal parameter 설정이 2개 필요함

```
cat /proc/sys/vm/max_map_count
cat /proc/sys/fs/file-nr

5024  0 131072

5024: 현재 열린 파일 디스크립터의 수
0: 사용 가능한 파일 디스크립터의 수
131072: fs.file-max 값

/etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=131072

sysctl -p
```

- 인증서

ca.crt 를 추가해야 https://elastic:9280 에 인증서 오류가 발생하지 않음

```
$ docker cp elastic:/usr/share/elasticsearch/config/certs/ca/ca.crt .
 
pwsh$ certutil -addstore root "C:\path\to\ca.crt"
```

- apiKey

elastic 의 environment 에 추가 되어야 함

```
environment:
  - xpack.security.enabled=true


POST /_security/api_key
{
  "name": "mkuser-python",
  "expiration": "1m",
  "role_descriptors": {
    "my_custom_role": {
      "cluster": ["all"],
      "index": [
        {
          "names": ["*"],
          "privileges": ["read", "create_index", "write"] # all
        }
      ]
    }
  }
}

{
  "id": "XBFrbJMB7ynkGV007RzE",
  "name": "mkuser-python",
  "expiration": 1732690892837,
  "api_key": "1GFVnJ50QWazw-H5VsFhvg",
  "encoded": "WEJGcmJKTUI3eW5rR1YwMDdSekU6MUdGVm5KNTBRV2F6dy1INVZzRmh2Zw=="
}

---

DELETE /_security/api_key
{
  "name": "mkuser-python"
}


https://www.elastic.co/guide/en/elasticsearch/client/python-api/current/connecting.html

from elasticsearch import Elasticsearch

# Adds the HTTP header 'Authorization: ApiKey <base64 api_key.id:api_key.api_key>'
client = Elasticsearch(
    "https://es01:9280",
    ca_certs="/path/to/http_ca.crt",
    api_key="api_key",
)

# Adds the HTTP header 'Authorization: Bearer token-value'
client = Elasticsearch(
    "https://es01:9280",
    bearer_auth="token-value"
)

# Adds the HTTP header 'Authorization: Basic <base64 username:password>'
client = Elasticsearch(
    "https://es01:9280",
    ca_certs="/path/to/http_ca.crt",
    basic_auth=("username", "password")
)


# certmgr.msc 에서 인증서 관리

```

- single 모드로 운영하면서 서비스명을 es01 을 elastic 로 변경했을 경우

ca.crt 파일의 인증서의 certificate's altnames 수정이 필요함

```
kibana    | [2024-12-02T05:52:05.670+00:00][ERROR][elasticsearch-service] Unable to retrieve version information from Elasticsearch nodes. Hostname/IP does not match certificate's altnames: Host: elastic. is not in the cert's altnames: DNS:es01, IP Address:127.0.0.1, DNS:localhost
kibana    | [2024-12-02T05:52:06.248+00:00][INFO ][plugins.screenshotting.chromium] Browser executable: /usr/share/kibana/node_modules/@kbn/sc
```

es-setup 의 volume, elastic_certs 에서 인증서 파일이 변경되었는지 확인

```
    volumes:
      - elastic_certs:/usr/share/elasticsearch/config/certs
    command: >
      bash -c '
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: elastic\n"\
          "    dns:\n"\
          "      - elastic\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://elastic:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:trustno1" -H "Content-Type: application/json" https://elastic:9200/_security/user/kibana_system/_password -d "{\"password\":\"trustno1\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
```

