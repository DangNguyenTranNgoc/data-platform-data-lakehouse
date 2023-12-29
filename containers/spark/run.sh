#!/bin/bash
# shellcheck disable=SC1091
set -o errexit
set -o nounset
set -o pipefail

# Load libraries
. /opt/bitnami/scripts/libspark.sh
. /opt/bitnami/scripts/libos.sh

# Load Spark environment settings
. /opt/bitnami/scripts/spark-env.sh

gen_base_conf() {
    cat << CONF
spark.jars                                     jars/*
spark.sql.extensions                           io.delta.sql.DeltaSparkSessionExtension
spark.sql.catalog.spark_catalog                org.apache.spark.sql.delta.catalog.DeltaCatalog
spark.eventLog.enabled                         true
spark.serializer                               org.apache.spark.serializer.KryoSerializer
spark.executor.extraJavaOptions                -Duser.timezone=Etc/UTC
spark.hadoop.fs.s3a.endpoint                   ${S3_ENDPOINT_URL}
spark.hadoop.fs.s3a.access.key                 ${AWS_ACCESS_KEY_ID}
spark.hadoop.fs.s3a.secret.key                 ${AWS_SECRET_ACCESS_KEY}
spark.hadoop.fs.s3a.aws.credentials.provider   org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider
spark.hadoop.fs.s3a.path.style.access          true
spark.hadoop.fs.s3a.connection.ssl.enabled     false
spark.hadoop.fs.s3a.impl                       org.apache.hadoop.fs.s3a.S3AFileSystem
CONF
}

gen_spark_defaults_conf() {
    gen_base_conf "$1"
}

gen_thriftserver_conf() {
    base_conf=$(gen_base_conf)
    cat << CONF >> "$1"
${base_conf}
spark.sql.warehouse.dir                        s3a://${S3_BUCKET}/${S3_PREFIX}/
spark.hadoop.hive.metastore.uris               ${HIVE_METASTORE_URL}
spark.hadoop.hive.metastore.warehouse.dir      s3a://${S3_BUCKET}/${S3_PREFIX}/
spark.hive.metastore.schema.verification       false
CONF
}

if [ "$SPARK_MODE" == "master" ]; then
    # Master constants
    EXEC=$(command -v start-master.sh)
    ARGS=()
    gen_spark_defaults_conf /opt/bitnami/spark/conf/spark-defaults.conf
    info "** Starting Spark in master mode **"
elif [ "$SPARK_MODE" == "thriftserver" ];then
    # Master constants
    EXEC=$(command -v start-thriftserver.sh)
    ARGS=()
    gen_thriftserver_conf /opt/bitnami/spark/conf/spark-defaults.conf
    info "** Starting Spark in thriftserver mode **"
else
    # Worker constants
    EXEC=$(command -v start-worker.sh)
    ARGS=("$SPARK_MASTER_URL")
    gen_spark_defaults_conf /opt/bitnami/spark/conf/spark-defaults.conf
    info "** Starting Spark in worker mode **"
fi
if am_i_root; then
    exec_as_user "$SPARK_DAEMON_USER" "$EXEC" "${ARGS[@]-}"
else
    exec "$EXEC" "${ARGS[@]-}"
fi
