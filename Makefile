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
	docker-compose --env-file .env up -V --abort-on-container-exit > ./logs/log_$(DATE).log 2>&1 &
.PHONY: up

down:
	docker-compose --env-file .env down
.PHONY: down

restart:
	make down && make up
.PHONY: restart

to_trino:
	docker exec -it $(TRINO_CONTAINER) trino --server http://127.0.0.1:8080
.PHONY: to_trino
