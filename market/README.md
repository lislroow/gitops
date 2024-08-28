
### 'cp-kafka' spring 'producer' 메시지 확인

`userProducer.send(model.map(entity, User.class));` 호출 시 'CustomOAuth2UserService.loadUser' 이름의 topic 이 생성됨

```java
import org.springframework.kafka.core.KafkaTemplate;

public class UserProducer {
  private KafkaTemplate<String, Object> template;
  public UserProducer(KafkaTemplate<String, Object> template) {
    this.template = template;
  }
  public void send(User user) {
    this.template.send("CustomOAuth2UserService.loadUser", user);
  }
}
```

spring 'producer' 에서 kafka 에 접속할 때는 아래 정보를 참조함

`INTERNAL` 는 Docker 컨테이너 내부 또는 Docker 네트워크 내에서 브로커에 접근할 때 사용
`EXTERNAL` 는 외부 클라이언트가 Kafka 브로커에 연결할 때 사용하는 listener  (`※netsh interface portproxy 사용 시 port 일치 시킬것`)
설정 변경 후 `docker-compose -f cp-kafka.yml up cp-kafka -d` 로 컨테이너 실행

```
services:
  cp-kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - 59092:59092
    environment:
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://cp-kafka:9092,EXTERNAL://mgkim.net:59092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
```

spring producer 실행 후 topic 및 topic 메시지 확인

```
$ kafka-topics --bootstrap-server localhost:9092 --list

CustomOAuth2UserService.loadUser
__consumer_offsets
cdc_customer
market-config
market-offsets
market-status

$ kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning --topic CustomOAuth2UserService.loadUser

{"id":"00u7uljhpo7g4k","password":"{bcrypt}$2a$10$mGLANNq3.4pVVcsIxlP/QehgBpdI.Vi91t7Di5YWlNsnTpHK5meOa","email":"mgkim.net@gmail.com","nickname":"무명왕","picture":"https://lh3.googleusercontent.com/a/ACg8ocLIczZ4384A_jJUKFy2u3yg7J-EGwwwRjdkgfrHoQ7T_H2ElSU=s96-c","role":"ROLE_USER","lockedYn":"N","dormantYn":"N","passwordExpireDate":[2024,11,23,18,7,55,195029700],"registrationId":"google","oauth2Id":"108568153386903408749","createDate":[2024,8,25,18,7,55,195029700],"modifyDate":[2024,8,25,18,7,55,195029700]}

kafka-topics --bootstrap-server localhost:9092 --delete --topic CustomOAuth2UserService.loadUser
```

### 'cp-kafka' cdc 구성

cdc 는 구성은 'from DB'에 source connector 를 추가하고, 'to DB'에 sink connector 를 추가하는 것

#### connector 추가 전 connector 목록 확인

```
curl -X GET http://mgkim.net:58083/connectors
[]
```

#### source connector 추가 'cdc-source-customer'

```
curl --location --request PUT 'http://mgkim.net:58083/connectors/cdc-source-customer/config' \
--header 'Content-Type: application/json' \
--data '{
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
    "connection.url": "jdbc:mariadb://mariadb-market-customer:3401/market-customer",
    "connection.user": "root",
    "connection.password": "1",
    "mode": "timestamp+incrementing",
    "incrementing.column.name": "id",
    "timestamp.column.name": "modify_date",
    "table.whitelist": "customer",
    "topic.prefix": "cdc_",
    "schema.pattern": "customer",
    "tasks.max": "3"
}'
```

```
# '/connectors/cdc-source-customer/config' 실행 결과
{"name":"cdc-source-customer","config":{"connector.class":"io.confluent.connect.jdbc.JdbcSourceConnector","connection.url":"jdbc:mariadb://mariadb-market-customer:3401/market-customer","connection.user":"root","connection.password":"1","mode":"timestamp+incrementing","incrementing.column.name":"id","timestamp.column.name":"modify_date","table.whitelist":"customer","topic.prefix":"cdc_","schema.pattern":"customer","tasks.max":"3","name":"cdc-source-customer"},"tasks":[],"type":"source"}

# connectors 목록 확인
curl -X GET http://mgkim.net:58083/connectors
["cdc-source-customer"]

# topic 확인
[appuser@2351c027ba61 ~]$ kafka-topics --bootstrap-server localhost:9092 --list
__consumer_offsets
cdc_customer
market-config
market-offsets
market-status
```

#### sink connector 추가 'cdc-sink-order-customer'

```
curl --location --request PUT 'http://mgkim.net:58083/connectors/cdc-sink-order-customer/config' \
--header 'Content-Type: application/json' \
--data '{
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "cdc_customer",
    "connection.url": "jdbc:mariadb://mariadb-market-delivery:3404/market-order",
    "connection.user": "root",
    "connection.password": "1",
    "table.name.format": "market-order.customer",
    "auto.create": "true",
    "auto.evolve": "true",
    "insert.mode": "insert",
    "pk.fields": "id",
    "pk.mode": "none",
    "delete.enabled": "false",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true"
}'
```

```
# '/connectors/cdc-source-customer/config' 실행 결과
{"name":"cdc-sink-order-customer","config":{"connector.class":"io.confluent.connect.jdbc.JdbcSinkConnector","tasks.max":"1","topics":"cdc_customer","connection.url":"jdbc:mariadb://mariadb-market-delivery:3404/market-order","connection.user":"root","connection.password":"1","table.name.format":"market-order.customer","auto.create":"true","auto.evolve":"true","insert.mode":"insert","pk.fields":"id","pk.mode":"none","delete.enabled":"false","key.converter":"org.apache.kafka.connect.json.JsonConverter","key.converter.schemas.enable":"true","value.converter":"org.apache.kafka.connect.json.JsonConverter","value.converter.schemas.enable":"true","name":"cdc-sink-order-customer"},"tasks":[],"type":"sink"}

# connectors 목록 확인
curl -X GET http://mgkim.net:58083/connectors
["cdc-source-customer","cdc-sink-order-customer"]

# topic 확인
[appuser@2351c027ba61 ~]$ kafka-topics --bootstrap-server localhost:9092 --list
__consumer_offsets
cdc_customer
market-config
market-offsets
market-status
```

#### 'cp-kafka' topic 메시지 확인

'cdc_customer' topic 은 기본 설치 후 바로 확인했으므로 없음으로 나옴

```bash
[appuser@2351c027ba61 bin]$ kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning --topic cdc_customer
[2024-08-25 04:12:48,879] WARN [Consumer clientId=console-consumer, groupId=console-consumer-67984] Error while fetching metadata with correlation id 2 : {cdc_customer=LEADER_NOT_AVAILABLE} (org.apache.kafka.clients.NetworkClient)
Processed a total of 0 messages
```

#### 'cp-kafka' topic 확인

```bash
[appuser@2351c027ba61 bin]$ kafka-topics --bootstrap-server localhost:9092 --list
__consumer_offsets
market-config
market-offsets
market-status
```

#### cp-kafka 컨테이너 명령어 확인

```bash
[root@rocky8-market ~]# docker exec -it cp-kafka bash
[appuser@2351c027ba61 ~]$ echo $PATH
ls -al /usr/bin | grep kafka
```

