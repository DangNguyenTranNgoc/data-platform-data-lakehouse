FROM apache/airflow:2.7.3

USER root

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_VERSION=3.5.0
ENV PATH=$PATH:/usr/local/spark/bin:/usr/lib/jvm/java-17-openjdk-amd64
ENV JAVA_VERSION=17.0.9

RUN apt-get update && \
    apt-get install -y software-properties-common gnupg2 procps && \
    apt-get install -y openjdk-17-jre && \
    java -version && \
    apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/ /var/cache/apt/archives

RUN \
    mkdir -p ${SPARK_HOME} && \
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    | tar zxv -C ${SPARK_HOME}

COPY helper.sh ${AIRFLOW_HOME}

RUN chmod +x ${AIRFLOW_HOME}/helper.sh

COPY requirements.txt .

RUN \
    pip install -r requirements.txt && \
    rm -f requirements.txt

USER ${AIRFLOW_UID}