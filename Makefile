.PHONY: build

build:
	docker buildx build --platform linux/amd64 -f Dockerfile . -t python-fips:latest
