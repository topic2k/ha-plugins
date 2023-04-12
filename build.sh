#!/usr/bin/env bash

export TMP_URL=~/tmp/ha-plugins-devel
export REPO_URL=https://github.com/topic2k/ha-plugins
export REPO_SSH=git@github.com:topic2k/ha-plugins.git

function check_environment () {
    if [ -z "$DOCKER_HUB_PASSWORD" ] || [ -z "$DOCKER_HUB_USER" ]
    then
        echo "\$DOCKER_HUB_PASSWORD and \$DOCKER_HUB_USER must be set"
        exit 1
    fi
}

case "$1" in
    docker-dev)
        check_environment
        docker run \
            --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock:ro \
            homeassistant/amd64-builder:dev \
            --no-cache --aarch64 \
            -t ha-sip-dev -r $REPO_URL -b dev \
            --docker-user "$DOCKER_HUB_USER" --docker-password "$DOCKER_HUB_PASSWORD"
        ;;
    build-dev)
        check_environment
        echo "Building on development branch (aarch64 only)..."
        if [ -z "$2" ]
          then
            echo "Don't overwrite version."
          else
            echo "Set version to $2"
            export OVERWRITE_VERSION=$2
            CONFIG_JSON=config.json
            contents="$(jq --indent 4 '.version = env.OVERWRITE_VERSION' $CONFIG_JSON)" && echo -E "${contents}" > $CONFIG_JSON
            git commit -a -m "Changes for development branch."
            git push
        fi
        docker run \
            --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock:ro \
            homeassistant/amd64-builder:dev \
            --no-cache --aarch64 \
            -t ha-sip -r $REPO_URL -b dev \
            --docker-user "$DOCKER_HUB_USER" --docker-password "$DOCKER_HUB_PASSWORD"
        ;;
    build)
        check_environment
        echo "Building prod for all archs..."
        docker run \
            --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock:ro \
            homeassistant/amd64-builder:dev \
            --no-cache --all \
            -t ha-sip -r $REPO_URL -b dev \
            --docker-user "$DOCKER_HUB_USER" --docker-password "$DOCKER_HUB_PASSWORD"
        ;;
    update)
        echo "Updating builder..."
        docker pull homeassistant/amd64-builder:dev
        ;;
    test)
        echo "Running type-check..."
        pyright ha-sip
        ;;
    create-venv)
        SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
        rm -rf $SCRIPT_DIR/venv $SCRIPT_DIR/deps
        python3 -m venv $SCRIPT_DIR/venv
        source $SCRIPT_DIR/venv/bin/activate
        pip3 install pydub requests PyYAML typing_extensions
        mkdir $SCRIPT_DIR/deps
        cd $SCRIPT_DIR/deps || exit
        git clone --depth 1 --branch 2.13 https://github.com/pjsip/pjproject.git
        cd pjproject || exit
        ./configure --enable-shared --disable-libwebrtc --prefix $SCRIPT_DIR/venv
        make
        make dep
        make install
        cd pjsip-apps/src/swig || exit
        make python
        cd python || exit
        python setup.py install
        ;;
    *)
        echo "Supply one of 'docker-dev', 'build-dev', 'build', 'test', 'update' or 'create-venv'"
        exit 1
        ;;
esac
