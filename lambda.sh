#/bin/bash

rm -rf $PWD/lambda

docker run \
    --rm \
    --tty \
    --volume $PWD/lambda:/out:rw \
    --workdir /usr/local \
dweomer/amazonlinux:git \
    sh -x -c "(tar -ch {bin,lib64,libexec,share} | tar -xhC /out) && chown -R $(id -u):$(id -g) /out"

docker run \
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
