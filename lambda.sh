#/bin/bash

set -e

: ${AMAZONLINUX_VERSION:=2017.03}
: ${GIT_VERSION:=2.14.1}
: ${OPENSSH_VERSION:=V_7_5_P1}

function ver() {
  echo $1 | sed -e 's/^V_//g' -e 's/_/./g' -e 's/\([.].*\)[.].*/\1/g'
}

LDIR=$(dirname $0)
RDIR=$(realpath -e $LDIR 2> /dev/null || readlink -f $LDIR) # mac and linux

DPKG=git-$(ver $GIT_VERSION)-openssh-$(ver $OPENSSH_VERSION)
DTAG=dweomer/amazonlinux:2017.03-${DPKG}

set -x

docker build \
    --build-arg "http_proxy=$http_proxy" \
    --build-arg "https_proxy=$https_proxy" \
    --build-arg "no_proxy=$no_proxy" \
    --build-arg "AMAZONLINUX_VERSION=$AMAZONLINUX_VERSION" \
    --build-arg "GIT_VERSION=$GIT_VERSION" \
    --build-arg "OPENSSH_VERSION=$OPENSSH_VERSION" \
    --tag $DTAG \
    $RDIR

rm -rf $PWD/lambda

docker run \
    --rm \
    --workdir /usr/local \
    $DTAG sh -x -c "tar -ch {bin,lib64,libexec,share}" > ${DPKG}.tar

docker run \
    --rm \
    --tty \
    --volume $PWD/lambda:/out:rw \
    --workdir /usr/local \
    $DTAG sh -x -c "(tar -ch {bin,lib64,libexec,share} | tar -xhC /out) && chown -R $(id -u):$(id -g) /out"

# this fails on mac because of the bind mounts lacking required info
[[ "$(uname -s)" == "Linux" ]] && docker run \
    --rm \
    --tty \
    --user $(id -u):$(id -g) \
    --env HOME \
    --env GIT_EXEC_PATH=/usr/local/libexec/git-core \
    --env GIT_TEMPLATE_DIR=/usr/local/share/git-core/templates \
    --volume $HOME:$HOME:ro \
    --volume /etc/shadow:/etc/shadow:ro \
    --volume /etc/passwd:/etc/passwd:ro \
    --volume /etc/group:/etc/group:ro \
    --volume $PWD/lambda:/usr/local:ro \
    --workdir /tmp \
amazonlinux:2017.03 \
    sh -x -c 'git clone ssh://git@github.com/github/dmca.git'
