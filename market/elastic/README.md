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

ca.crt + es01.crt 2개가 추가되어야 https://es01:9280 에 인증서 오류가 발생하지 않음

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



