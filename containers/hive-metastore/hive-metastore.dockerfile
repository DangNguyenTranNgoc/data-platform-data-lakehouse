FROM openjdk:16-slim

# Lifted from: https://github.com/joshuarobinson/presto-on-k8s/blob/1c91f0b97c3b7b58bdcdec5ad6697b42e50d74c7/hive_metastore/Dockerfile

# see https://hadoop.apache.org/releases.html
ARG HADOOP_VERSION=3.3.0
# see https://downloads.apache.org/hive/
ARG HIVE_METASTORE_VERSION=3.0.0
# see https://jdbc.postgresql.org/download.html#current
ARG POSTGRES_CONNECTOR_VERSION=42.2.18

# Set necessary environment variables.
ENV HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"\ 
    HIVE_HOME="/opt/apache-hive-metastore-${HIVE_METASTORE_VERSION}-bin"\
    PATH="/opt/spark/bin:/opt/hadoop/bin:${PATH}"\
    DATABASE_DRIVER=org.postgresql.Driver\
    DATABASE_TYPE=postgres\
    DATABASE_TYPE_JDBC=postgresql\
    DATABASE_PORT=5432

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN \
  echo "Install OS dependencies" && \
    build_deps="curl" && \
    apt-get update -y && \
    apt-get install -y $build_deps net-tools --no-install-recommends && \
  echo "Download and extract the Hadoop binary package" && \
    curl https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
    | tar xvz -C /opt/ && \
    ln -s $HADOOP_HOME /opt/hadoop && \
    rm -r ${HADOOP_HOME}/share/doc && \
  echo "Add S3a jars to the classpath using this hack" && \
    ln -s ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws* ${HADOOP_HOME}/share/hadoop/common/lib/ && \
    ln -s ${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk* ${HADOOP_HOME}/share/hadoop/common/lib/ && \
  echo "Download and install the standalone metastore binary" && \
    curl https://downloads.apache.org/hive/hive-standalone-metastore-$HIVE_METASTORE_VERSION/hive-standalone-metastore-$HIVE_METASTORE_VERSION-bin.tar.gz \
    | tar xvz -C /opt/ && \
    ln -s $HIVE_HOME /opt/hive-metastore && \
  echo "Fix 'java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument'" && \
  echo "Keep this until this lands: https://issues.apache.org/jira/browse/HIVE-22915" && \
    rm ${HIVE_HOME}/lib/guava-19.0.jar && \
    cp ${HADOOP_HOME}/share/hadoop/hdfs/lib/guava-27.0-jre.jar ${HIVE_HOME}/lib/ && \
  echo "Download and install the database connector" && \
    curl -L https://jdbc.postgresql.org/download/postgresql-$POSTGRES_CONNECTOR_VERSION.jar --output /opt/postgresql-$POSTGRES_CONNECTOR_VERSION.jar && \
    ln -s /opt/postgresql-$POSTGRES_CONNECTOR_VERSION.jar ${HADOOP_HOME}/share/hadoop/common/lib/ && \
    ln -s /opt/postgresql-$POSTGRES_CONNECTOR_VERSION.jar ${HIVE_HOME}/lib/&& \
  echo "Purge build artifacts" && \
    apt-get purge -y --auto-remove $build_deps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh run.sh

RUN groupadd -r hive --gid=1001 && \
    useradd -r -g hive --uid=1001 -d ${HIVE_HOME}/ hive && \
    chown hive:hive -R ${HIVE_HOME}/ && \
    mkdir -p /user/hive && \
    chown hive:hive -R /user/hive

USER hive
EXPOSE 9083
EXPOSE 10000

CMD [ "./run.sh" ]
