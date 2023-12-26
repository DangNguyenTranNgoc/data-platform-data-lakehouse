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
