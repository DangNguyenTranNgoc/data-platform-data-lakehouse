FROM apache/airflow:2.7.3

USER root

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\
    SPARK_HOME=/usr/local/spark\
    SPARK_VERSION=3.5.0\
    PATH=$PATH:/usr/local/spark/bin

RUN apt-get update && \
    apt-get install -y software-properties-common gnupg2 procps && \
    add-apt-repository "deb http://security.debian.org/debian-security stretch/updates main" && \ 
    apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    java -version && \
    javac -version && \
    apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/ /var/cache/apt/archives

RUN \
    mkdir -p ${SPARK_HOME} && \
    mkdir -p "${SPARK_HOME}/assembly/target/scala-2.12.18/jars" && \
    curl "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    | tar -xvzf -C ${SPARK_HOME} && \
    cp -a "spark-${SPARK_VERSION}-bin-hadoop3/jars/." "${SPARK_HOME}/assembly/target/scala-2.12.18/jars/" && \
    rm "spark-${SPARK_VERSION}-bin-hadoop3.tgz"

COPY requirements.txt .

RUN \
    pip install -r requirements.txt && \
    rm -f requirements.txt

USER ${AIRFLOW_UID}
