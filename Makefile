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

up: build
	docker-compose up --env-file .env -V --abort-on-container-exit > log_$(DATE).log 2>&1 &
	while ! (docker-compose logs app | grep 'Starting Metastore'); do sleep 1 && printf .; done
.PHONY: up

down:
	docker-compose --env-file .env down
.PHONY: down

restart:
	make down && make up
.PHONY: restart
