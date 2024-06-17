.PHONY: build build-3.9 build-wolfi-3.9 build-3.11 build-wolfi-3.11 build-3.12 build-wolfi-3.12

build-3.9:
	docker buildx build --platform linux/amd64 -f Dockerfile-3.9.rocky . -t python-fips-3.9:latest

build-wolfi-3.9:
	docker buildx build --platform linux/amd64 -f Dockerfile-3.9.wolfi . -t python-fips-wolfi-3.9:latest

build-3.11:
	docker buildx build -f Dockerfile-3.11.rocky . -t python-fips-3.11:latest

build-wolfi-3.11:
	docker buildx build -f Dockerfile-3.11.wolfi . -t python-fips-wolfi-3.11:latest

build-3.12:
	docker buildx build -f Dockerfile-3.12.rocky . -t python-fips-3.12:latest

build-wolfi-3.12:
	docker buildx build -f Dockerfile-3.12.wolfi -t python-fips-wolfi-3.12:latest

build:
	build-3.9
	build-wolfi-3.9
	build-3.11
	build-wolfi-3.11
	build-3.12
	build-wolfi-3.12
