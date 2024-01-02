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

resource "docker_container" "hive_metastore" {
  name = "hive-metastore"
  image = docker_image.hive_metastore.image_id
  depends_on = [ 
    docker_container.postgres, 
    null_resource.hive_metastore_folder,
    docker_container.minio,
    docker_network.data_platform_net
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
