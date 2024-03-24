# python-fips
Dockerfile(s) for experiementing with Python x FIPS

## Getting started

The initial Dockerfile is based on Rocky Linux.

To build the image, either run `make build` or run the full `docker buildx build` command:
```sh
docker buildx build --platform linux/amd64 -f Dockerfile . -t python-fips:latest
```

For now, using `linux/amd64` is recommended since ARM64 is most likely unsupported from a FIPS-standpoint (TBD, though).

The image is comprised of two stages:
1. `patch`
2. primary/build

The `patch` stage downloads the Python archive and applies the contents of `fips.patch` to the necessary files. The Python code is copied over into the primary stage where it is built after OpenSSL.

## Contents

The contents of the Dockerfile are minimal -- only the packages and dependencies needed to build OpenSSL and Python are included. That said, the image size comes out to be ~875MB.

The `patch` stage installs the following:
- `patchutils` 
- `wget`

Then downloads the versioned Python Archive and patches the following files in the extracted Python directory:
- `Lib/ssl.py`
- `Modules/Setup`
- `Modules/_ssl.c`
- `Modules/clinic/_ssl.c.h`

The primary stage installs the following:
- `autoconf`
- `automake`
- `bzip2-devel`
- `diffutils`
- `gcc`
- `libffi-devel`
- `libffi`
- `libjpeg-devel`
- `libssh-devel`
- `libtool`
- `libxml2-devel`
- `libxslt-devel`
- `make`
- `wget`
- `zlib-devel`

Then downloads the OpenSSL archives (both the FIPS module and primary release) and builds both OpenSSL and Python before finishing up with an installation of a specific version of `cryptography`.

## Usage
After the image is built, start a container and test it out:
```sh
❯ docker run --rm -it --entrypoint bash python-fips:latest
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
bash-5.1# python3
Python 3.9.18 (main, Jan 15 2024, 02:39:33)
[GCC 11.4.1 20230605 (Red Hat 11.4.1-2)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import ssl
>>> ssl.OPENSSL_VERSION
'OpenSSL 1.0.2u-fips  20 Dec 2019'
>>> ssl.FIPS_mode()
0
>>> ssl.FIPS_mode_set(1)
>>> ssl.FIPS_mode()
1
```

## Troubleshooting

Building Python with a specifc OpenSSL version can be pretty tedious. 

If building OpenSSL using `--prefix=/some/path`, ensure that the Python build reflects this by adding `--with-openssl=/some/path/openssl` to the `configure` step.

Also, adding `-Wl,-rpath=/opt/python-fips/lib` to `LDFLAGS` during the Python `./configure` step along with `echo "/opt/python-fips/lib" > /etc/ld.so.conf.d/python.conf` + `ldconfig -v` can resolve some library issues (and even enable the correct detection of the new Python installation).

More discussing on this can be found here:
- https://stackoverflow.com/a/38781440

The most common issue I ran into while building this Dockerfile (which was much harder than doing locally in a VM, even in WSL2 or in EC2) was that Python would build against the wrong OpenSSL version or the Python installation would not be the correct one (i.e., the system Python -- even when overwriting it or using `make altinstall`).

The configuration in the `Dockerfile` works and can serve as a starting point for other implementations.

Something to note: the feedback loop for doing cross-arch builds on an M1 Mac is very slow (25-30 minutes E2E). For troubleshooting, starting a container that has already been built and trying new/different commands is faster than building from scratch each time. This is especially useful if OpenSSL has been installed correctly but Python isn't building as expected.

## Acknowledgements

Huge shoutout to GyanBlog for the following posts that inspired this work and made the process much less painful (even though it was still fairly arduous):
- https://www.gyanblog.com/security/dockerfile-fips-enabled-python-with-openssl/
- https://www.gyanblog.com/security/how-build-patch-python-3.9.x-fips-enable/
- https://www.gyanblog.com/security/how-build-patch-python-3.7.9-fips-enable/ 

The patch code is also c/o GyanBlog -- I only made a few tweaks to the file paths in the file so that `patch` could find them automatically inside of the extracted Python directory without needing manual intervention.

## TODO

The Dockerfile is fairly clean but can be optimized further.

The idea for using a Docker image is that it can be used for Lambdas or as a way to pull out the built Python binary (TBD how well that works, though). 

That said, it's also way more reproducible than spinning up EC2 instances and doing this manually (though an AMI made via Packer would get around this).
