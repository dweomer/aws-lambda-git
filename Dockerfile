ARG AMAZONLINUX_VERSION=2017.03
ARG GIT_VERSION=2.14.1
ARG OPENSSH_VERSION=V_7_5_P1

FROM amazonlinux:${AMAZONLINUX_VERSION} as staticish_build

ARG CFLAGS=

ARG http_proxy=
ARG https_proxy=
ARG no_proxy=

RUN set -x \
 && export http_proxy="$http_proxy" \
 && export https_proxy="$https_proxy" \
 && export no_proxy="$no_proxy" \
 && yum install -y \
    autoconf \
    automake \
    expat-devel \
    findutils \
    gcc \
    gettext \
    glibc-static \
    libcurl \
    libcurl-devel \
    libssh2-devel \
    make \
    openssl-devel \
    perl-ExtUtils-Install \
    python27-devel \
    tar \
    tcl \
    xz \
    zlib-devel

ENV CFLAGS="${CFLAGS} -static-libgcc"


# Build a static-ish git
FROM staticish_build as staticish_git

ARG GIT_VERSION

WORKDIR /usr/local/src/git-${GIT_VERSION}

ARG http_proxy=
ARG https_proxy=
ARG no_proxy=

RUN set -x \
 && export http_proxy=$http_proxy \
 && export https_proxy=$https_proxy \
 && export no_proxy=$no_proxy \
 && curl -fsSL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz | tar -xJC /usr/local/src \
 && make prefix=/opt CFLAGS="${CFLAGS}" \
 && make prefix=/opt CFLAGS="${CFLAGS}" install \
 && eval 'PATH=/opt/bin:$PATH git --version'


# Build a static-ish ssh
FROM staticish_build as staticish_ssh

ARG OPENSSH_VERSION

WORKDIR /usr/local/src/openssh-portable-${OPENSSH_VERSION}

ARG http_proxy=
ARG https_proxy=
ARG no_proxy=

RUN set -x \
 && export http_proxy=$http_proxy \
 && export https_proxy=$https_proxy \
 && export no_proxy=$no_proxy \
 && curl -fsSL https://github.com/openssh/openssh-portable/archive/${OPENSSH_VERSION}.tar.gz | tar -xzC /usr/local/src \
 && autoheader \
 && autoconf \
 && ./configure \
    --prefix=/opt \
    --without-pam \
    --without-shadow \
 && make \
 && make install \
 && rm -rf /opt/sbin  \
 && eval 'PATH=/opt/bin:$PATH ssh -V'

# Collect all the binaries
FROM amazonlinux:${AMAZONLINUX_VERSION}

COPY --from=staticish_git /opt/ /usr/local/
COPY --from=staticish_ssh /opt/ /usr/local/

ENV GIT_EXEC_PATH=/usr/local/libexec/git-core \
    GIT_TEMPLATE_DIR=/usr/local/share/git-core/templates
