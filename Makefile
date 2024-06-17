.PHONY: build build-3.9 build-wolfi-3.9 build-3.11 build-wolfi-3.11 build-3.12 build-wolfi-3.12

### Python 3.9 ###
build-3.9:
	docker buildx build --platform linux/amd64 -f python-3.9/rocky/Dockerfile . -t python-fips-3.9:latest
build-wolfi-3.9:
	docker buildx build --platform linux/amd64 -f python-3.9/wolfi/Dockerfile . -t python-fips-wolfi-3.9:latest

### Python 3.11 ###
build-3.11:
	docker buildx build -f python-3.11/rocky/Dockerfile . -t python-fips-3.11:latest
build-wolfi-3.11:
	docker buildx build -f python-3.11/wolfi/Dockerfile . -t python-fips-wolfi-3.11:latest

### Python 3.12 ###
build-3.12:
	docker buildx build -f python-3.12/rocky/Dockerfile . -t python-fips-3.12:latest
build-wolfi-3.12:
	docker buildx build -f python-3.12/wolfi/Dockerfile -t python-fips-wolfi-3.12:latest

### All ###
build:
	build-3.9
	build-wolfi-3.9
	build-3.11
	build-wolfi-3.11
	build-3.12
	build-wolfi-3.12
