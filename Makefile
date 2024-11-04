SHELL := /bin/bash
LUA_BIN := $(PWD)/packages/bin
KONG_VERSION := "2.8.1"

install:
	pongo
	
up:
	docker compose up -d mock
	KONG_VERSION=$(KONG_VERSION) pongo up

down:
	docker compose down
	pongo down

pongo:
	(cd /tmp && git clone https://github.com/Kong/kong-pongo.git)
	ln -s /tmp/kong-pongo/pongo.sh $(HOME)/.local/bin/pongo

lint:
	pongo lint

test:
	KONG_VERSION=$(KONG_VERSION) pongo run -- --Xoutput "--color" --coverage