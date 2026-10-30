.PHONY: init build up prod-up migrate prod-migrate test down prod-down

M ?= 002-add-sku.sql
APP_VERSION ?= 1.4.3
GIT_SHA ?= local

init:
	./bin/init-local.sh

build: init
	docker build --build-arg APP_VERSION=$(APP_VERSION) --build-arg GIT_SHA=$(GIT_SHA) -t shopapi:tp04 ./apps/shopapi
	docker build --secret id=pipconf,src=secrets/pip.conf --build-arg APP_VERSION=$(APP_VERSION) --build-arg GIT_SHA=$(GIT_SHA) -t shop-worker:tp04 ./apps/shop-worker

up: build
	docker compose up -d --no-build --wait

prod-up: init
	docker compose -f compose.yml -f compose.prod.yml up -d --wait

migrate: init
	MIGRATION="$(M)" docker compose run --rm migrate

prod-migrate: init
	MIGRATION="$(M)" docker compose -f compose.yml -f compose.prod.yml run --rm migrate

test:
	./smoke-test.sh

down:
	docker compose down

prod-down:
	docker compose -f compose.yml -f compose.prod.yml down
