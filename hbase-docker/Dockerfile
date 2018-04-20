# HBase in Docker

# http://docs.docker.io/en/latest/use/builder/

FROM centos:7

RUN yum install -y java-1.8.0-openjdk \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && curl -o /usr/local/sbin/tini -SL "https://github.com/krallin/tini/releases/download/v0.16.1/tini-static-amd64" \
    && curl -o /usr/local/sbin/tini.asc -SL "https://github.com/krallin/tini/releases/download/v0.16.1/tini-static-amd64.asc" \
    && gpg --verify /usr/local/sbin/tini.asc \
    && rm /usr/local/sbin/tini.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/sbin/tini

ENV HBASE_LOCAL_ZOOKEEPER="yes"
ENV HBASE_SHARED_STORAGE="no"
ENV HBASE_ENABLE_THRIFT="yes"
ENV HBASE_ENABLE_REST="yes"
ENV HBASE_ENABLE_REGIONSERVER="yes"
ENV HBASE_ENABLE_MASTER="yes"
ENV HADOOP_HOME="/opt/hadoop"
ENV HADOOP_CONF_DIR="/opt/hadoop/etc/hadoop"
ENV YARN_CONF_DIR="/opt/hadoop/etc/hadoop"
ENV HADOOP_YARN_USER="hbase"
ENV HADOOP_ENABLE_NAMENODE="no"
ENV HADOOP_ENABLE_DATANODE="no"
ENV HADOOP_NAMENODE_URL="hdfs://localhost/"
ENV ENABLE_KERBEROS="no"

WORKDIR /opt

RUN curl -o /opt/hbase.tar.gz -LS http://archive.apache.org/dist/hbase/1.3.1/hbase-1.3.1-bin.tar.gz \
    && curl -o /opt/hadoop.tar.gz -LS http://archive.apache.org/dist/hadoop/hadoop-2.8.0.tar.gz \
    && curl -o /opt/phoenix.tar.gz -LS http://archive.apache.org/dist/phoenix/apache-phoenix-4.13.0-HBase-1.3/bin/apache-phoenix-4.13.0-HBase-1.3-bin.tar.gz \
    && tar xf /opt/hbase.tar.gz \
    && tar xf /opt/hadoop.tar.gz \
    && tar xf /opt/phoenix.tar.gz \
    && mv /opt/hbase-* /opt/hbase \
    && mv /opt/hadoop-* /opt/hadoop \
    && mv /opt/apache-phoenix-* /opt/apache-phoenix \
    && mv /opt/apache-phoenix/*.jar /opt/hbase/lib/ \
    && rm -f /opt/*.tar.gz \
    && adduser --system hbase \
    && chown -R hbase:hbase /opt/hbase/conf \
    && chown -R hbase:hbase /opt/hadoop/etc/hadoop \
    && mkdir /data \
    && chown -R hbase:hbase /data \
    && yum install -y which krb5-workstation; yum clean all; rm -rf /var/cache/yum

ADD replace-hostname  /opt/
ADD server            /opt/
ADD hbase-site.xml          /opt/hbase/conf/
ADD hbase-site.xml.kerberos /opt/hbase/conf/
ADD zoo.cfg                 /opt/hbase/conf/
ADD log4j.properties        /opt/hbase/conf/
ADD ssl-client.xml          /opt/hadoop/etc/hadoop/
ADD ssl-server.xml          /opt/hadoop/etc/hadoop/
ADD log4j.properties        /opt/hadoop/etc/hadoop/
ADD hdfs-site.xml           /opt/hadoop/etc/hadoop/
ADD hdfs-site.xml.kerberos  /opt/hadoop/etc/hadoop/
ADD core-site.xml           /opt/hadoop/etc/hadoop/
ADD core-site.xml.kerberos  /opt/hadoop/etc/hadoop/

VOLUME ["/data"]

# Hadoop Name Node
EXPOSE 8020
# REST API
EXPOSE 8080
# REST Web UI at :8085/rest.jsp
EXPOSE 8085
# Thrift API
EXPOSE 9090
# Thrift Web UI at :9095/thrift.jsp
EXPOSE 9095
# HBase's Embedded zookeeper cluster
EXPOSE 2181
# HBase Master web UI at :16010/master-status;  ZK at :16010/zk.jsp
EXPOSE 16000
EXPOSE 16010
EXPOSE 16020
EXPOSE 16030

# Hadoop DFS Datanode
EXPOSE 50010
# Hadoop DFS IPC
EXPOSE 50020
# Hadoop NameNode WebUI
EXPOSE 50070
EXPOSE 50470
# Hadoop DFS Datanode http
EXPOSE 50075
EXPOSE 50475

WORKDIR /
USER hbase
ENTRYPOINT ["/usr/local/sbin/tini", "--"]
CMD ["/opt/server"]
