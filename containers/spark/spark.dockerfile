FROM bitnami/spark:3.5-debian-11

USER root

# hadolint ignore=DL3008
RUN \
    echo "=== Install OS dependencies ===" && \
        build_deps="curl" && \
        apt-get update -y && \
        apt-get install -y $build_deps rsync --no-install-recommends && \
    echo "=== Download needed jar files ===" && \
        curl -o /opt/bitnami/spark/jars/delta-spark_2.12-3.0.0.jar https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.0.0/delta-spark_2.12-3.0.0.jar && \
        curl -o /opt/bitnami/spark/jars/hadoop-aws-3.3.4.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar && \
        curl -o /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.12.262.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar && \
        curl -o /opt/bitnami/spark/jars/postgresql-42.6.0.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.6.0/postgresql-42.6.0.jar && \
    echo "=== Purge build artifacts ===" && \
        apt-get purge -y --auto-remove $build_deps && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/ /var/cache/apt/archives

COPY ./run.sh /opt/bitnami/scripts/spark/
COPY ./libspark.sh /opt/bitnami/scripts/

RUN chmod g+rwX /opt/bitnami/ && \
    mkdir /tmp/spark-events && \
    chmod g+rw /tmp/spark-events

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/spark/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/spark/run.sh" ]
