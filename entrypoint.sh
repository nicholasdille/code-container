#!/usr/bin/dumb-init /bin/bash
set -e

# User
export EDITOR_USER_NAME=editor
export EDITOR_GROUP_NAME=editor
EDITOR_UID="${EDITOR_UID:-10001}"
EDITOR_GID="${EDITOR_GID:-10001}"
EDITOR_USER="${EDITOR_UID}:${EDITOR_GID}"
groupadd -g "${EDITOR_GID}" "${EDITOR_GROUP_NAME}" || \
    groupmod -n "${EDITOR_GROUP_NAME}" $(getent group "$EDITOR_GID" | cut -d: -f1) || \
    true
useradd -m -u "${EDITOR_UID}" -g "${EDITOR_GID}" -G 0 -s /bin/bash "${EDITOR_USER_NAME}"

# Hosts
if [ ! -z "${EDITOR_LOCALHOST_ALIASES}" ]; then
    set +e
    LOCALHOST="127.0.0.1"
    DOCKER_INTERNAL=$(host host.docker.internal | head -n1 | awk '{print $NF}')
    if [ ! -z "${DOCKER_INTERNAL}" ]; then
        LOCALHOST="${DOCKER_INTERNAL}"
        # include special hostname as an alias for localhost
        EDITOR_LOCALHOST_ALIASES="localhost;${EDITOR_LOCALHOST_ALIASES}"
    fi
    set -e
    IFS=";"
    for LOCALHOST_ALIAS in ${EDITOR_LOCALHOST_ALIASES}; do
        echo "${LOCALHOST} ${LOCALHOST_ALIAS}" >> /etc/hosts
    done
fi

# Docker
if [ -z "${DOCKER_HOST}" ]; then
    if [ -S /var/run/docker.sock ]; then
        # Expose Docker unix socket as a TCP server
        # https://github.com/cdr/code-server/issues/436
        socat TCP-LISTEN:2376,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock &>/dev/null &
        export DOCKER_HOST=tcp://127.0.0.1:2376

    else
        usermod -aG docker editor
        /usr/local/bin/dind /usr/bin/dockerd --storage-driver vfs &
    fi
fi

/su-exec ${EDITOR_USER_NAME} /editor.sh