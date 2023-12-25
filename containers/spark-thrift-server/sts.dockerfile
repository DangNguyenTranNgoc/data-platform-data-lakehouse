ARG OPENJDK_VERSION=8
FROM eclipse-temurin:${OPENJDK_VERSION}-jre

ARG BUILD_DATE
ARG SPARK_VERSION=3.3.2
ARG HADOOP_VERSION=3

LABEL org.label-schema.name="Apache Spark ${SPARK_VERSION}" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$SPARK_VERSION

ENV SPARK_HOME /usr/spark
ENV PATH="/usr/spark/bin:/usr/spark/sbin:${PATH}"

RUN apt-get update && \
    apt-get install -y wget netcat procps libpostgresql-jdbc-java && \
    wget -q "http://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    tar xzf "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mv "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" /usr/spark && \
    ln -s /usr/share/java/postgresql-jdbc4.jar /usr/spark/jars/postgresql-jdbc4.jar && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean

COPY run.sh run.sh

RUN groupadd -r spark --gid=1001 && \
    useradd -r -g spark --uid=1001 -d ${HIVE_HOME}/ hive && \
    chown hive:hive -R ${HIVE_HOME}/ && \
    mkdir -p /user/hive && \
    chown hive:hive -R /user/hive

USER spark
EXPOSE 9083
EXPOSE 10000

CMD [ "./run.sh" ]
