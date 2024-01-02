variable "POSTGRES_HOST" {
  type = string
  default = "postgres"
}

variable "POSTGRES_DB" {
  type = string
  default = "metastore"
}

variable "POSTGRES_USER" {
  type = string
  default = "admin"
}

variable "POSTGRES_PASSWORD" {
  type = string
  default = "admin123"
}

variable "POSTGRES_HOST_AUTH_METHOD" {
  type = string
  default = "trust"
}

variable "MINIO_ROOT_USER" {
  type = string
  default = "minio"
}

variable "MINIO_ROOT_PASSWORD" {
  type = string
  default = "minio123"
}

variable "MINIO_ACCESS_KEY" {
  type = string
  default = "minio"
}

variable "MINIO_SECRET_KEY" {
  type = string
  default = "minio123"
}

variable "AWS_ACCESS_KEY_ID" {
  type = string
  default = "minio"
}

variable "AWS_SECRET_KEY" {
  type = string
  default = "minio123"
}

variable "S3_ENDPOINT_URL" {
  type = string
  default = "http://minio:9000"
}

variable "S3_BUCKET" {
  type = string
  default = "warehouse"
}

variable "S3_PREFIX" {
  type = string
  default = "default"
}

# Basic Airflow cluster configuration for CeleryExecutor with Redis and PostgreSQL.
#
# WARNING: This configuration is for local development. Do not use it in a production deployment.
#
# This configuration supports basic configuration using environment variables or an .env file
# The following variables are supported:
#
# AIRFLOW_IMAGE_NAME           - Docker image name used to run Airflow.
#                                Default: apache/airflow:2.8.0
# AIRFLOW_UID                  - User ID in Airflow containers
#                                Default: 50000
# AIRFLOW_PROJ_DIR             - Base path to which all the files will be volumed.
#                                Default: .
# Those configurations are useful mostly in case of standalone testing/running Airflow in test/try-out mode
#
# _AIRFLOW_WWW_USER_USERNAME   - Username for the administrator account (if requested).
#                                Default: airflow
# _AIRFLOW_WWW_USER_PASSWORD   - Password for the administrator account (if requested).
#                                Default: airflow
# _PIP_ADDITIONAL_REQUIREMENTS - Additional PIP requirements to add when starting all containers.
#                                Use this option ONLY for quick checks. Installing requirements at container
#                                startup is done EVERY TIME the service is started.
#                                A better way is to build a custom image or extend the official image
#                                as described in https://airflow.apache.org/docs/docker-stack/build.html.
#                                Default: ''
variable "AIRFLOW__CORE__EXECUTOR" {
  type = string
  default = "CeleryExecutor"
}
variable "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" {
  type = string
  default = "postgresql+psycopg2://${var.POSTGRES_USER}:${var.POSTGRES_PASSWORD}@${var.POSTGRES_HOST}/airflow"
}
variable "AIRFLOW__CELERY__RESULT_BACKEND" {
  type = string
  default = "db+postgresql://${var.POSTGRES_USER}:${var.POSTGRES_PASSWORD}@${var.POSTGRES_HOST}/airflow"
}
variable "AIRFLOW__CELERY__BROKER_URL" {
  type = string
  default = "redis://:@redis:6379/0"
}
variable "AIRFLOW__CORE__FERNET_KEY" {
  type = string
  default = ""
}
variable "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION" {
  type = string
  default = "true"
}
variable "AIRFLOW__CORE__LOAD_EXAMPLES" {
  type = string
  default = "true"
}
variable "AIRFLOW__API__AUTH_BACKENDS" {
  type = string
  default = "airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session"
}
variable "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK" {
  type = string
  default = "true"
}

