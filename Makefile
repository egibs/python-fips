.PHONY: build

build:
	docker buildx build --platform linux/amd64 -f Dockerfile . -t python-fips:latest

build-wolfi:
	docker buildx build --platform linux/amd64 -f Dockerfile.wolfi . -t python-fips:latest
