# Patch Python to support OpenSSL FIPS module
# Patchutils installs Python which we want to avoid in the final image
FROM --platform=$TARGETPLATFORM rockylinux:9-minimal@sha256:305de618a5681ff75b1d608fd22b10f362867dff2f550a4f1d427d21cd7f42b4 as patch

ARG PYTHON_VERSION="3.9.19"

RUN microdnf -y update \
    && microdnf install -y \
    patchutils \
    tar \
    wget

WORKDIR /fips

COPY fips_3.9.patch fips.patch
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar -xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && patch -p1 < ../fips.patch \
    && cd -

# Main stage
FROM --platform=$TARGETPLATFORM rockylinux:9-minimal@sha256:305de618a5681ff75b1d608fd22b10f362867dff2f550a4f1d427d21cd7f42b4 as build

ARG OPENSSL_BASE_VERSION="1.0.2"
ARG OPENSSL_FIPS_VERSION="openssl-fips-2.0.16"
ARG OPENSSL_VERSION="openssl-${OPENSSL_BASE_VERSION}u"
ARG PYTHON_VERSION="3.9.19"
ARG TARGETPLATFORM

ENV OPENSSL_FIPS=1

WORKDIR /fips

COPY --from=patch /fips/Python-${PYTHON_VERSION} ./Python-${PYTHON_VERSION}

# Install dependencies
RUN microdnf -y update \
    && microdnf -y install \
    autoconf \
    automake \
    bzip2-devel \
    diffutils \
    gcc \
    libffi \
    libffi-devel \
    libjpeg-devel \
    libssh-devel \
    libtool \
    libxml2-devel \
    libxslt-devel \
    make \
    wget \
    zlib-devel \
    && microdnf clean all

# Download archives
RUN wget https://www.openssl.org/source/old/fips/${OPENSSL_FIPS_VERSION}.tar.gz \
    && wget https://www.openssl.org/source/old/${OPENSSL_BASE_VERSION}/${OPENSSL_VERSION}.tar.gz

# Extract archives
RUN tar -xzf ${OPENSSL_FIPS_VERSION}.tar.gz \
    && tar -xzf ${OPENSSL_VERSION}.tar.gz

# Build and Install OpenSSL FIPS Module
RUN cd ${OPENSSL_FIPS_VERSION} \
    && ./config \
    && make \
    && make install \
    && ldconfig -v \
    && cd -

# Build and Install OpenSSL
RUN cd ${OPENSSL_VERSION} \
    && ./config shared fips no-ssl2 no-ssl3 \
    && make depend \
    && make \
    && make install \
    && echo "/usr/local/ssl/lib" > /etc/ld.so.conf.d/${OPENSSL_VERSION}.conf \
    && ln -s -f /usr/local/ssl/bin/openssl /usr/bin/openssl \
    && ln -s -f /usr/local/ssl/bin/openssl /usr/local/bin/openssl \
    && ldconfig -v \
    && cd -

# Build and Install Python
RUN cd Python-${PYTHON_VERSION} \
    && LDFLAGS="-L/usr/local/lib/ -L/usr/local/lib64/ -Wl,-rpath=/opt/python-fips/lib" LD_LIBRARY_PATH="/usr/local/lib/:/usr/local/lib64/" CPPFLAGS="-I/usr/local/include -I/usr/local/ssl/include" ./configure --enable-shared --enable-optimizations --with-builtin-hashlib-hashes=sha1,sha256,sha512,sha3 --prefix=/opt/python-fips \
    && make \
    && make install \
    && echo "/opt/python-fips/lib" > /etc/ld.so.conf.d/python.conf \
    && ldconfig -v \
    && ln -s -f /opt/python-fips/bin/python3.9 /usr/bin/python3 \
    && ln -s -f /opt/python-fips/bin/python3.9 /usr/local/bin/python3 \
    && cd -

# Install Python dependencies
RUN python3 -m pip install wheel \
    && python3 -m pip install --upgrade pip setuptools \
    && CRYPTOGRAPHY_DONT_BUILD_RUST=1 CFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib" python3 -m pip wheel --no-binary :all: cryptography==3.0 \
    && CRYPTOGRAPHY_DONT_BUILD_RUST=1 CFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib" python3 -m pip install cryptography-3.0-cp39-cp39-linux_x86_64.whl

RUN groupadd python && useradd -m -g python python \
    && install -d -o python -g python /home/python

USER python
