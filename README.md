# python-fips

Dockerfile(s) for experiementing with Python x FIPS

## Getting started

Build any of the supported Dockerfiles via their respective Makefile targets.

### Support Matrix

| Python Version | Linux Distribution | OpenSSL Version | Architecture
| --- | --- | --- | --- |
| `3.9.19` | Rocky 9 | `1.0.2u` (Base) </b> `2.0.16` (FIPS provider) | `linux/amd64`
| `3.9.19` | Wolfi | `1.0.2.u` (Base) </b> `2.0.16` (FIPS provider) | `linux/amd64`
| `3.11.9` | Rocky 9 | `3.0.9` | `linux/amd64` </b> `linux/arm64`
| `3.11.9` | Wolfi | `3.0.9` | `linux/amd64` </b> `linux/arm64`
| `3.12.3` | Rocky 9 | `3.0.9` | `linux/amd64` </b> `linux/arm64`
| `3.12.3` | Wolfi | `3.0.9` | `linux/amd64` </b> `linux/arm64`

> OpenSSL `3.0.9` is the latest FIPS-approved version of OpenSSL; while it is possible to use the latest OpenSSL release and use `3.0.9` to handle the FIPS provider portion, it's not approved or supported.

To build the image, either run `make build` or run the full `docker buildx build` command, e.g.:
```sh
docker buildx build -f Dockerfile-3.11.wolfi . -t python-fips-wolfi-3.11:latest
```

> For the `3.9` images, using `linux/amd64` is recommended since ARM64 is most likely unsupported from a FIPS-standpoint (TBD, though).


The image is comprised of two stages:

1. `patch`
2. primary/build

The `patch` stage downloads the Python archive and applies the contents of `fips.patch` to the necessary files. The Python code is copied over into the primary stage where it is built after OpenSSL.

## Contents

The contents of the Dockerfile are minimal -- only the packages and dependencies needed to build OpenSSL and Python are included.

The `patch` stage installs the following:

- `patchutils` (Rocky); `patch` (Wolfi)
- `wget`

Then downloads the versioned Python Archive and patches various Python source files depending on the Python release and the contents of the `fips_*.patch` files.

The primary stage installs the following on the Rocky variants:
- `autoconf`
- `automake`
- `bzip2-devel`
- `diffutils`
- `gcc`
- `libffi`
- `libffi-devel`
- `libjpeg-devel`
- `libssh-devel`
- `libtool`
- `libxml2-devel`
- `libxslt-devel`
- `make`
- `perl`
- `wget`
- `zlib-devel`

and the following on the Wolfi variants:
- `autoconf`
- `automake`
- `bzip2-dev`
- `diffutils`
- `gcc`
- `glibc`
- `glibc-dev`
- `ld-linux`
- `libffi`
- `libffi-dev`
- `libjpeg-dev`
- `libssh-dev`
- `libtool`
- `libxml2-dev`
- `libxslt-dev`
- `make`
- `perl`
- `wgets`
- `zlib-dev`

Then downloads the OpenSSL archives (both the FIPS module and primary release) and builds both OpenSSL and Python before finishing up with an installation of a specific version of `cryptography`.

## Usage

### Python3.9

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

### Python3.11 and Python3.12

The output for the newer Python and OpenSSL versions is a little messier since FIPS is handled differently, but the important part is this:
```
>> hashlib.new("sha256")
<sha256 _hashlib.HASH object @ 0xffffa117be10>
>>> hashlib.new("md5")
Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 165, in __hash_new
    return _hashlib.new(name, data, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_hashlib.UnsupportedDigestmodError: [digital envelope routines] unsupported

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 171, in __hash_new
    return __get_builtin_constructor(name)(data)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 87, in __get_builtin_constructor
    raise ValueError('unsupported hash type ' + name + '(in FIPS mode)')
ValueError: unsupported hash type md5(in FIPS mode)
```

`md5` and `blake2*` are not supported under FIPS.

```sh
a0817bb0b9e3:/# python3
Python 3.12.3 (main, Apr 28 2024, 23:05:04) [GCC 13.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import ssl
>>> ssl.OPENSSL_VERSION
'OpenSSL 3.0.9 30 May 2023'
>>> import hashlib
ERROR:root:code for hash md5 was not found.
Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 142, in __get_openssl_constructor
    f(usedforsecurity=False)
_hashlib.UnsupportedDigestmodError: [digital envelope routines] unsupported

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 250, in <module>
    globals()[__func_name] = __get_hash(__func_name)
                             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 146, in __get_openssl_constructor
    return __get_builtin_constructor(name)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 87, in __get_builtin_constructor
    raise ValueError('unsupported hash type ' + name + '(in FIPS mode)')
ValueError: unsupported hash type md5(in FIPS mode)
ERROR:root:code for hash blake2b was not found.
Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 142, in __get_openssl_constructor
    f(usedforsecurity=False)
_hashlib.UnsupportedDigestmodError: [digital envelope routines] unsupported

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 250, in <module>
    globals()[__func_name] = __get_hash(__func_name)
                             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 146, in __get_openssl_constructor
    return __get_builtin_constructor(name)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 87, in __get_builtin_constructor
    raise ValueError('unsupported hash type ' + name + '(in FIPS mode)')
ValueError: unsupported hash type blake2b(in FIPS mode)
ERROR:root:code for hash blake2s was not found.
Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 142, in __get_openssl_constructor
    f(usedforsecurity=False)
_hashlib.UnsupportedDigestmodError: [digital envelope routines] unsupported

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 250, in <module>
    globals()[__func_name] = __get_hash(__func_name)
                             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 146, in __get_openssl_constructor
    return __get_builtin_constructor(name)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 87, in __get_builtin_constructor
    raise ValueError('unsupported hash type ' + name + '(in FIPS mode)')
ValueError: unsupported hash type blake2s(in FIPS mode)
>>> hashlib.new("sha256")
<sha256 _hashlib.HASH object @ 0xffffa117be10>
>>> hashlib.new("md5")
Traceback (most recent call last):
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 165, in __hash_new
    return _hashlib.new(name, data, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_hashlib.UnsupportedDigestmodError: [digital envelope routines] unsupported

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 171, in __hash_new
    return __get_builtin_constructor(name)(data)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/python-fips/lib/python3.12/hashlib.py", line 87, in __get_builtin_constructor
    raise ValueError('unsupported hash type ' + name + '(in FIPS mode)')
ValueError: unsupported hash type md5(in FIPS mode)
```

## Troubleshooting

Building Python with a specifc OpenSSL version can be pretty tedious.

If building OpenSSL using `--prefix=/some/path`, ensure that the Python build reflects this by adding `--with-openssl=/some/path/openssl` to the `configure` step.

Also, adding `-Wl,-rpath=/opt/python-fips/lib` to `LDFLAGS` during the Python `./configure` step along with `echo "/opt/python-fips/lib" > /etc/ld.so.conf.d/python.conf` + `ldconfig -v` can resolve some library issues (and even enable the correct detection of the new Python installation).

More discussing on this can be found here:

- https://stackoverflow.com/a/38781440

When building OpenSSL 3.x, specifying both `--prefix` and `--openssldir` is recommended so that the `<1.1.0` behavior is more or less replicated.

More on this can be found here:
- https://wiki.openssl.org/index.php/Compilation_and_Installation

The most common issue I ran into while building this Dockerfile (which was much harder than doing locally in a VM, even in WSL2 or in EC2) was that Python would build against the wrong OpenSSL version or the Python installation would not be the correct one (i.e., the system Python -- even when overwriting it or using `make altinstall`).

The configuration in the `Dockerfile` works and can serve as a starting point for other implementations.

Something to note: the feedback loop for doing cross-arch builds on an M1 Mac is very slow (25-30 minutes E2E). For troubleshooting, starting a container that has already been built and trying new/different commands is faster than building from scratch each time. This is especially useful if OpenSSL has been installed correctly but Python isn't building as expected.

## Acknowledgements

Huge shoutout to GyanBlog for the following posts that inspired this work and made the process much less painful (even though it was still fairly arduous):

- https://www.gyanblog.com/security/dockerfile-fips-enabled-python-with-openssl/
- https://www.gyanblog.com/security/how-build-patch-python-3.9.x-fips-enable/
- https://www.gyanblog.com/security/how-build-patch-python-3.7.9-fips-enable/

The 3.9 patch code is also c/o GyanBlog -- I only made a few tweaks to the file paths in the file so that `patch` could find them automatically inside of the extracted Python directory without needing manual intervention.

Upstream Python3.11/3.12 patches can be found here:
- https://gitlab.com/redhat/centos-stream/rpms/python3.11/-/blob/c8s/00329-fips.patch?ref_type=heads
- https://gitlab.com/redhat/centos-stream/rpms/python3.12/-/blob/c8s/00329-fips.patch?ref_type=heads

This repo made small tweaks to `Lib/py_compile.py` in the 3.11 patch and `Lib/hmac.py` in the 3.12 patch, respectively. The patching process would not succeed otherwise.

## TODO

The Dockerfiles are fairly clean but can be optimized further.

The idea for using a Docker image is that it can be used for Lambdas or as a way to pull out the built Python binary (TBD how well that works, though).

That said, it's also way more reproducible than spinning up EC2 instances and doing this manually (though an AMI made via Packer would get around this).

## Why?

Just to see if I could, really. 

This is a very heavy process and not at all recommended if you can avoid it. The wonderful folks at Chainguard have FIPS variants of their Python images if you _really_ need this.
