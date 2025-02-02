MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

WGET = /usr/bin/env wget --timestamping --no-verbose

.DEFAULT_GOAL := all
SHELL := bash

.PHONY: all
all: install-requirements format test

# https://www.gnu.org/software/make/manual/html_node/Force-Targets.html
FORCE:

.PHONY: install-poetry
install-poetry:
	pip install poetry

install-requirements: install-poetry
	poetry install

.PHONY: test
test:
	poetry run python -m pytest --ignore=source_template

.PHONY: clean
clean:
	rm -rf `find . -name __pycache__`
	rm -f `find . -type f -name '*.py[co]' `
	rm -rf .pytest_cache
	rm -rf dist

.PHONY: lint
lint:
	poetry run flake8 --exit-zero --max-line-length 120 monarch_ingest/ tests/
	poetry run black --check --diff monarch_ingest tests
	poetry run isort --check-only --diff monarch_ingest tests

.PHONY: format
format:
	poetry run autoflake \
		--recursive \
		--remove-all-unused-imports \
		--remove-unused-variables \
		--ignore-init-module-imports \
		--in-place monarch_ingest tests
	poetry run isort monarch_ingest tests
	poetry run black monarch_ingest tests

data/:
	mkdir --parents $@

data/omim/: data/
	mkdir --parents $@

data/hpoa/:
	mkdir --parents $@

.PHONY: download
download:
	gsutil -m cp -R gs://monarch-ingest/data .

.PHONY: download-kozacache
download-kozacache:
	gsutil -m cp -R gs://koza-cache/data .

.PHONY: download-omim
download-omim: data/omim/mimTitles.txt data/omim/morbidmap.txt data/omim/mim2gene.txt

.PHONY: download-hpoa
download-hpoa: data/hpoa/phenotype.hpoa

.PHONY: upload-omim
upload-omim: data/omim/mimTitles.txt data/omim/morbidmap.txt data/omim/mim2gene.txt
	gsutil -m cp $^ gs://koza-cache/$(<D)/

.PHONY: upload-hpoa
upload-hpoa: data/hpoa/phenotype.hpoa
	gsutil -m cp $^ gs://koza-cache/$(<D)/

# Mind the @ to not leak the key
data/omim/mimTitles.txt: FORCE data/omim/
	@cd $(@D) && $(WGET) $(MONARCHIVE)$(MONARCHIVE_KEY)/mimTitles.txt

# Mind the @ to not leak the key
data/omim/morbidmap.txt: FORCE data/omim/
	@cd $(@D) && $(WGET) $(MONARCHIVE)$(MONARCHIVE_KEY)/morbidmap.txt

data/omim/mim2gene.txt: FORCE data/omim/
	cd $(@D) && $(WGET) https://www.omim.org/static/omim/data/mim2gene.txt

data/hpoa/phenotype.hpoa: FORCE data/hpoa/
	cd $(@D) && $(WGET) http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa

.PHONY: transform
transform:
	poetry run dagster job execute

.PHONY: merge
merge:
	poetry run kgx merge --merge-config merge.yaml

.PHONY: neo4j-load
neo4j-load:
	poetry run kgx transform --stream --transform-config neo-transform.yaml

.PHONY: upload
upload:
	gsutil cp output/merged/monarch-kg.tar.gz gs://monarch-ingest/
	gsutil cp output/merged/monarch-kg.nt.gz gs://monarch-ingest/
	gsutil cp merged_graph_stats.yaml gs://monarch-ingest/

.PHONY: run_dagster
run_dagster:
	 poetry run dagit
