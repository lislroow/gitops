FROM confluentinc/cp-kafka-connect:7.6.1

ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
    CUSTOM_CONNECTOR_PATH="/usr/share/java"

ARG CONNECT_TRANSFORM_VERSION=1.4.6
ARG KAFKA_CONNECT_JDBC_VERSION=10.7.6
ARG DEBEZIUM_MYSQL_VERSION=2.6.1.Final
ARG DEBEZIUM_MARIADB_VERSION=2.7.0.Alpha1

RUN confluent-hub install --no-prompt confluentinc/connect-transforms:$CONNECT_TRANSFORM_VERSION
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:$KAFKA_CONNECT_JDBC_VERSION

RUN cd $CUSTOM_CONNECTOR_PATH && \
    curl -sO https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/$DEBEZIUM_MYSQL_VERSION/debezium-connector-mysql-$DEBEZIUM_MYSQL_VERSION-plugin.zip && \
    jar xvf debezium-connector-mysql-$DEBEZIUM_MYSQL_VERSION-plugin.zip && \
    rm debezium-connector-mysql-$DEBEZIUM_MYSQL_VERSION-plugin.zip

RUN cd $CUSTOM_CONNECTOR_PATH && \
    curl -sO https://repo1.maven.org/maven2/io/debezium/debezium-connector-mariadb/$DEBEZIUM_MARIADB_VERSION/debezium-connector-mariadb-$DEBEZIUM_MARIADB_VERSION-plugin.zip && \
    jar xvf debezium-connector-mariadb-$DEBEZIUM_MARIADB_VERSION-plugin.zip && \
    rm debezium-connector-mariadb-$DEBEZIUM_MARIADB_VERSION-plugin.zip

RUN cd /etc/kafka-connect/jars && \
    curl -sO https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/3.3.3/mariadb-java-client-3.3.3.jar && \
    curl -sO https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
