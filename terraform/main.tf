terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  # Run [docker context ls] command to find out your Docker Enpoint
  host = "unix:///var/run/docker.sock"
}

locals {
  module_path        = abspath(path.module)
  codebase_root_path = abspath("${path.module}/..")
  # Trim local.codebase_root_path and one additional slash from local.module_path
  module_rel_path    = substr(local.module_path, length(local.codebase_root_path)+1, length(local.module_path))
}

###########################
## Define used resources ##
###########################

resource "docker_image" "hive_metastore" {
  name = "hive-metastore"
  keep_locally = true
  build {
    context = "${local.codebase_root_path}/containers/hive-metastore/"
    dockerfile = "hive-metastore.dockerfile"
    tag = ["hive-metastore:dev"]
  }
}

resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_image" "trino" {
  name = "trinodb/trino:latest"
  keep_locally = true
}

resource "docker_image" "minio" {
  name = "quay.io/minio/minio:latest"
  keep_locally = true
}

resource "docker_image" "spark" {
  name = "spark"
  keep_locally = true
  build {
    context = "${local.codebase_root_path}/containers/spark/"
    dockerfile = "spark.dockerfile"
    tag = ["spark:dev"]
  }
}

resource "docker_image" "airflow" {
  name = "airflow"
  keep_locally = true
  build {
    context = "${local.codebase_root_path}/containers/airflow/"
    dockerfile = "airflow.dockerfile"
    tag = ["airflow:dev"]
  }
}

resource "docker_image" "redis" {
  name = "qredis:latest"
  keep_locally = true
}

resource "docker_network" "data_platform_net" {
  name = "data_platform_net"
  driver = "bridge"
}

###########################
## Prepare Mount folders ##
###########################

resource "null_resource" "create_postgres_data_folder" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.codebase_root_path}/mnt/postgresql/"
  }
}

resource "null_resource" "hive_metastore_folder" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.codebase_root_path}/mnt/hive/"
  }
}

resource "null_resource" "minio_folder" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.codebase_root_path}/mnt/minio/"
  }
}

# Create folder for airflow
resource "null_resource" "airflow_folder" {
  provisioner "local-exec" {
    command = <<EOF
mkdir -p /sources/logs /sources/dags /sources/plugins
chown -R "${var.AIRFLOW_UID}:0" /sources/{logs,dags,plugins}
EOF
  }
}

######################
## Define container ##
######################

# Storage Layer

resource "docker_container" "postgres" {
  name = "postgres"
  image = docker_image.postgres.image_id
  depends_on = [ 
    null_resource.create_postgres_data_folder,
    docker_network.data_platform_net 
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  ports {
    internal = 5432
    external = 5432
  }
  volumes {
    container_path = "/var/lib/postgresql/data"
    host_path = "${local.codebase_root_path}/mnt/postgresql/"
  }
  healthcheck {
    test = [ "CMD", "psql", "-U", "${var.POSTGRES_USER}", "${var.POSTGRES_DB}" ]
  }
  hostname = "postgres"
  env = [ 
    "POSTGRES_USER=${var.POSTGRES_USER}",
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
    "POSTGRES_DB=${var.POSTGRES_DB}",
    ]
}

resource "null_resource" "run_ansible_init_database" {
  depends_on = [ docker_container.postgres ]
  provisioner "local-exec" {
    command = <<EOF
ansible-playbook -i ${local.codebase_root_path}/ansible/inventory \
                ${local.codebase_root_path}/ansible/init-database.yml
EOF
  }
}

resource "docker_container" "hive_metastore" {
  name = "hive-metastore"
  image = docker_image.hive_metastore.image_id
  depends_on = [ 
    docker_container.postgres, 
    null_resource.hive_metastore_folder,
    docker_container.minio,
    docker_network.data_platform_net,
    null_resource.run_ansible_init_database
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  volumes {
    container_path = "/user/hive"
    host_path = "${local.codebase_root_path}/mnt/hive/"
  }
  hostname = "hive-metastore"
  env = [ 
    "DATABASE_HOST=${var.POSTGRES_HOST}",
    "DATABASE_USER=${var.POSTGRES_USER}",
    "DATABASE_PASSWORD=${var.POSTGRES_PASSWORD}",
    "DATABASE_DB=${var.POSTGRES_DB}",
    "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}",
    "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY}",
    "S3_ENDPOINT_URL=${var.S3_ENDPOINT_URL}",
    "S3_BUCKET=${var.S3_BUCKET}",
    "S3_PREFIX=${var.S3_PREFIX}"
    ]
}

resource "docker_container" "trino" {
  name = "trino"
  image = docker_image.trino.image_id
  hostname = "trino"
  user = "1000:1000"
  depends_on = [ docker_network.data_platform_net ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  ports {
    internal = 8080
    external = 8080
  }
  volumes {
    container_path = "/etc/trino"
    host_path = "${local.codebase_root_path}/mnt/trino-etc"
  }
  healthcheck {
    test = ["CMD", "curl", "-f", "http://localhost:8080"]
  }
}

resource "docker_container" "minio" {
  name = "minio"
  image = docker_image.minio.image_id
  hostname = "minio"
  user = "1000:1000"
  depends_on = [ 
    null_resource.minio_folder, 
    docker_network.data_platform_net
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  ports {
    internal = 9000
    external = 9000
  }
  ports {
    internal = 9090
    external = 9090
  }
  volumes {
    container_path = "/data"
    host_path = "${local.codebase_root_path}/mnt/minio"
  }
  command = [ "server", "/data", "--console-address", ":9090" ]
  env = [ 
    "MINIO_ROOT_USER=${var.MINIO_ROOT_USER}",
    "MINIO_ROOT_PASSWORD=${var.MINIO_ROOT_PASSWORD}"
   ]
}

# Transform Layer

resource "docker_container" "spark_thrift_server" {
  name = "spark-thrift-server"
  image = docker_image.spark.image_id
  hostname = "spark-thrift-server"
  depends_on = [
    docker_container.hive_metastore,
    docker_container.minio,
    docker_container.spark_master,
    docker_network.data_platform_net
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  volumes {
    container_path = "/usr/local/share/data/"
    host_path = "${local.codebase_root_path}/data/"
  }
  env = [ 
    "SPARK_MODE=thriftserver",
    "SPARK_MASTER=spark://spark-master:7077",
    "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}",
    "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY}",
    "S3_ENDPOINT_URL=${var.S3_ENDPOINT_URL}",
    "S3_BUCKET=${var.S3_BUCKET}",
    "S3_PREFIX=${var.S3_PREFIX}",
    "SPARK_WORKER_CORES=1",
    "SPARK_DRIVER_MEMORY=512m",
    "SPARK_EXECUTOR_MEMORY=512m",
    "HIVE_METASTORE_URL=thrift://hive-metastore:9083",
    ]
}

resource "docker_container" "spark_master" {
  name = "spark-master"
  image = docker_image.spark.image_id
  hostname = "spark"
  depends_on = [
    docker_network.data_platform_net
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  ports {
    internal = 8080
    external = 8181
  }
  volumes {
    container_path = "/usr/local/share/data/"
    host_path = "${local.codebase_root_path}/data/"
  }
  env = [ 
    "SPARK_MODE=master",
    "S3_ENDPOINT_URL=${var.S3_ENDPOINT_URL}",
    "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}",
    "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY}"
   ]
}

resource "docker_container" "spark_worker_1" {
  name = "spark-worker-1"
  image = docker_image.spark.image_id
  depends_on = [
    docker_network.data_platform_net,
    docker_container.spark_master
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  env = [ 
    "SPARK_MODE=worker",
    "SPARK_MASTER_URL=spark://spark:7077",
    "SPARK_WORKER_MEMORY=4G",
    "SPARK_WORKER_CORES=1",
    "S3_ENDPOINT_URL=${var.S3_ENDPOINT_URL}",
    "AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}",
    "AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY}"
   ]
}

# Orchestration Layer

resource "docker_container" "redis" {
  name = "redis"
  hostname = "redis"
  image = docker_image.redis.image_id
  depends_on = [
    docker_network.data_platform_net
    ]
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  healthcheck {
    test = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout = "30s"
    retries = 50
    start_period = "30s"
  }
}

resource "docker_container" "airflow_webserver" {
  name = "airflow-webserver"
  image = docker_image.airflow.image_id
  hostname = "airflow-webserver"
  depends_on = [ 
    docker_container.postgres,
    docker_container.redis,
    null_resource.run_ansible_init_database
  ]
  user = "50000:0"
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  ports {
    internal = 8080
    external = 7070
  }
  command = ["webserver"]
  healthcheck {
    test = ["CMD", "curl", "--fail", "http://localhost:8080/health"]
    interval = "10s"
    timeout = "30s"
    retries = 50
    start_period = "30s"
  }
  volumes {
    container_path = "/opt/airflow/dags"
    host_path = "${local.codebase_root_path}/mnt/airflow/dags"
  }
  volumes {
    container_path = "/opt/airflow/logs"
    host_path = "${local.codebase_root_path}/mnt/airflow/logs"
  }
  volumes {
    container_path = "/opt/airflow/config"
    host_path = "${local.codebase_root_path}/mnt/airflow/config"
  }
  volumes {
    container_path = "/opt/airflow/plugins"
    host_path = "${local.codebase_root_path}/mnt/airflow/plugins"
  }
  env = [
    "AIRFLOW_UID=${var.AIRFLOW_UID}",
    "AIRFLOW__CORE__EXECUTOR=${var.AIRFLOW__CORE__EXECUTOR}",
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=${var.AIRFLOW__DATABASE__SQL_ALCHEMY_CONN}",
    "AIRFLOW__CELERY__RESULT_BACKEND=${var.AIRFLOW__CELERY__RESULT_BACKEND}",
    "AIRFLOW__CELERY__BROKER_URL=${var.AIRFLOW__CELERY__BROKER_URL}",
    "AIRFLOW__CORE__FERNET_KEY=${var.AIRFLOW__CORE__FERNET_KEY}",
    "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=${var.AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION}",
    "AIRFLOW__CORE__LOAD_EXAMPLES=${var.AIRFLOW__CORE__LOAD_EXAMPLES}",
    "AIRFLOW__API__AUTH_BACKENDS=${var.AIRFLOW__API__AUTH_BACKENDS}",
    "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=${var.AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK}"
   ]
}

resource "docker_container" "airflow_scheduler" {
  name = "airflow-scheduler"
  image = docker_image.airflow.image_id
  hostname = "airflow-scheduler"
  depends_on = [ 
    docker_container.postgres,
    docker_container.redis,
    null_resource.run_ansible_init_database
  ]
  wait = true
  user = "50000:0"
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  command = ["scheduler"]
  healthcheck {
    test = ["CMD", "curl", "--fail", "http://localhost:8080/health"]
    interval = "10s"
    timeout = "30s"
    retries = 50
    start_period = "30s"
  }
  volumes {
    container_path = "/opt/airflow/dags"
    host_path = "${local.codebase_root_path}/mnt/airflow/dags"
  }
  volumes {
    container_path = "/opt/airflow/logs"
    host_path = "${local.codebase_root_path}/mnt/airflow/logs"
  }
  volumes {
    container_path = "/opt/airflow/config"
    host_path = "${local.codebase_root_path}/mnt/airflow/config"
  }
  volumes {
    container_path = "/opt/airflow/plugins"
    host_path = "${local.codebase_root_path}/mnt/airflow/plugins"
  }
  env = [
    "AIRFLOW_UID=${var.AIRFLOW_UID}",
    "AIRFLOW__CORE__EXECUTOR=${var.AIRFLOW__CORE__EXECUTOR}",
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=${var.AIRFLOW__DATABASE__SQL_ALCHEMY_CONN}",
    "AIRFLOW__CELERY__RESULT_BACKEND=${var.AIRFLOW__CELERY__RESULT_BACKEND}",
    "AIRFLOW__CELERY__BROKER_URL=${var.AIRFLOW__CELERY__BROKER_URL}",
    "AIRFLOW__CORE__FERNET_KEY=${var.AIRFLOW__CORE__FERNET_KEY}",
    "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=${var.AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION}",
    "AIRFLOW__CORE__LOAD_EXAMPLES=${var.AIRFLOW__CORE__LOAD_EXAMPLES}",
    "AIRFLOW__API__AUTH_BACKENDS=${var.AIRFLOW__API__AUTH_BACKENDS}",
    "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=${var.AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK}"
   ]
}

resource "docker_container" "airflow_worker" {
  name = "airflow-worker"
  image = docker_image.airflow.image_id
  depends_on = [ 
    docker_container.postgres,
    docker_container.redis,
    null_resource.run_ansible_init_database
  ]
  user = "50000:0"
  wait = true
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  command = ["celery worker"]
  healthcheck {
    test = ["CMD-SHELL", "curl", "--fail", "celery --app airflow.providers.celery.executors.celery_executor.app inspect ping -d 'celery@$${HOSTNAME}' || celery --app airflow.executors.celery_executor.app inspect ping -d 'celery@$${HOSTNAME}'"]
    interval = "10s"
    timeout = "30s"
    retries = 50
    start_period = "30s"
  }
  volumes {
    container_path = "/opt/airflow/dags"
    host_path = "${local.codebase_root_path}/mnt/airflow/dags"
  }
  volumes {
    container_path = "/opt/airflow/logs"
    host_path = "${local.codebase_root_path}/mnt/airflow/logs"
  }
  volumes {
    container_path = "/opt/airflow/config"
    host_path = "${local.codebase_root_path}/mnt/airflow/config"
  }
  volumes {
    container_path = "/opt/airflow/plugins"
    host_path = "${local.codebase_root_path}/mnt/airflow/plugins"
  }
  env = [
    "AIRFLOW_UID=${var.AIRFLOW_UID}",
    "DUMB_INIT_SETSID=0",
    "AIRFLOW__CORE__EXECUTOR=${var.AIRFLOW__CORE__EXECUTOR}",
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=${var.AIRFLOW__DATABASE__SQL_ALCHEMY_CONN}",
    "AIRFLOW__CELERY__RESULT_BACKEND=${var.AIRFLOW__CELERY__RESULT_BACKEND}",
    "AIRFLOW__CELERY__BROKER_URL=${var.AIRFLOW__CELERY__BROKER_URL}",
    "AIRFLOW__CORE__FERNET_KEY=${var.AIRFLOW__CORE__FERNET_KEY}",
    "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=${var.AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION}",
    "AIRFLOW__CORE__LOAD_EXAMPLES=${var.AIRFLOW__CORE__LOAD_EXAMPLES}",
    "AIRFLOW__API__AUTH_BACKENDS=${var.AIRFLOW__API__AUTH_BACKENDS}",
    "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=${var.AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK}"
   ]
}

resource "docker_container" "airflow_triggerer" {
  name = "airflow-triggerer"
  image = docker_image.airflow.image_id
  hostname = "airflow-triggerer"
  depends_on = [ 
    docker_container.postgres,
    docker_container.redis,
    null_resource.run_ansible_init_database
  ]
  wait = true
  user = "50000:0"
  networks_advanced {
    name = docker_network.data_platform_net.id
  }
  command = ["triggerer"]
  healthcheck {
    test = ["CMD", "airflow jobs check --job-type TriggererJob --hostname '$${HOSTNAME}'"]
    interval = "10s"
    timeout = "30s"
    retries = 50
    start_period = "30s"
  }
  volumes {
    container_path = "/opt/airflow/dags"
    host_path = "${local.codebase_root_path}/mnt/airflow/dags"
  }
  volumes {
    container_path = "/opt/airflow/logs"
    host_path = "${local.codebase_root_path}/mnt/airflow/logs"
  }
  volumes {
    container_path = "/opt/airflow/config"
    host_path = "${local.codebase_root_path}/mnt/airflow/config"
  }
  volumes {
    container_path = "/opt/airflow/plugins"
    host_path = "${local.codebase_root_path}/mnt/airflow/plugins"
  }
  env = [
    "AIRFLOW_UID=${var.AIRFLOW_UID}",
    "AIRFLOW__CORE__EXECUTOR=${var.AIRFLOW__CORE__EXECUTOR}",
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=${var.AIRFLOW__DATABASE__SQL_ALCHEMY_CONN}",
    "AIRFLOW__CELERY__RESULT_BACKEND=${var.AIRFLOW__CELERY__RESULT_BACKEND}",
    "AIRFLOW__CELERY__BROKER_URL=${var.AIRFLOW__CELERY__BROKER_URL}",
    "AIRFLOW__CORE__FERNET_KEY=${var.AIRFLOW__CORE__FERNET_KEY}",
    "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=${var.AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION}",
    "AIRFLOW__CORE__LOAD_EXAMPLES=${var.AIRFLOW__CORE__LOAD_EXAMPLES}",
    "AIRFLOW__API__AUTH_BACKENDS=${var.AIRFLOW__API__AUTH_BACKENDS}",
    "AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=${var.AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK}"
   ]
}
