include .env
DKVERSION?=$(shell docker-compose -v)
ifneq (,$(findstring v2.,$(DKVERSION)))
	SEPARATOR:=-
else
	SEPARATOR:=_
endif
# Get name of containers
TRINO_CONTAINER?=$(shell basename $(CURDIR))$(SEPARATOR)trino$(SEPARATOR)1

DATE := $(shell date +"%Y_%m_%d-%H_%M_%S")
define HELP

Available commands:

- build: Build this project

- env-up: Boot up development environment

- env-down: Tear down development environment

- help: Display this help message

endef

export HELP
help:
	@echo "$$HELP"
.PHONY: help

build:
	docker-compose build
.PHONY: build

up:
	docker-compose --env-file .env up -V > ./logs/log_$(DATE).log 2>&1 &
.PHONY: up

up-database:
	docker-compose --profile database --env-file .env up -V > ./logs/log_$(DATE).log 2>&1 &
.PHONY: up-database

down:
	docker-compose --env-file .env down
.PHONY: down

down-database:
	docker-compose --profile database --env-file .env down
.PHONY: down-database

restart:
	make down && make up
.PHONY: restart

clean-logs:
	rm -f logs/*.log
.PHONY: clean-logs

to-trino:
	docker exec -it trino trino --server http://127.0.0.1:8080
.PHONY: to-trino

to-psql:
	docker exec -it postgres psql postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
.PHONY: to-psql

to-dbt:
	docker exec -it dbt-contianer /bin/bash
.PHONY: to-dbt

check-dbt:
	docker exec -it dbt-contianer dbt debug --project-dir metastore/ --profiles-dir ./
.PHONY: check-dbt

#######################
## Terraform is here ##
#######################

tf-apply:
	terraform -chdir=terraform apply
.PHONY: tf-apply

tf-destroy:
	terraform -chdir=terraform destroy
.PHONY: tf-destroy

tf-core-apply:
	terraform -chdir=terraform apply \
		-target="docker_container.postgres" \
		-target="docker_container.hive_metastore" \
		-target="docker_container.trino" \
		-target="docker_container.minio"
.PHONY: tf-core-apply

tf-core-destroy:
	terraform -chdir=terraform destroy \
		-target="docker_container.postgres" \
		-target="docker_container.hive_metastore" \
		-target="docker_container.trino" \
		-target="docker_container.minio"
.PHONY: tf-core-destroy

tf-transfom-apply:
	terraform -chdir=terraform apply \
		-target="docker_container.spark_thrift_server" \
		-target="docker_container.spark_master" \
		-target="docker_container.spark_worker_1"
.PHONY: tf-transfom-apply

tf-transfom-destroy:
	terraform -chdir=terraform destroy \
		-target="docker_container.spark_thrift_server" \
		-target="docker_container.spark_master" \
		-target="docker_container.spark_worker_1"
.PHONY: tf-transfom-destroy

tf-orchest-apply:
	terraform -chdir=terraform apply \
		-target="redis" \
		-target="airflow_webserver" \
		-target="airflow_scheduler" \
		-target="airflow_worker" \
		-target="airflow_triggerer"
.PHONY: tf-orchest-apply

tf-orchest-destroy:
	terraform -chdir=terraform destroy \
		-target="redis" \
		-target="airflow_webserver" \
		-target="airflow_scheduler" \
		-target="airflow_worker" \
		-target="airflow_triggerer"
.PHONY: tf-orchest-destroy
