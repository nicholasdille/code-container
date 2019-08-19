#!/bin/bash
set -e

# Project
if mountpoint /files >/dev/null 2>&1; then
    mkdir -p "/files/project"
    ln -sf "/files/project" "/home/${EDITOR_USER_NAME}/project"
else
    mkdir -p "/home/${EDITOR_USER_NAME}/project"
fi
cp -f /completion.sh "/home/${EDITOR_USER_NAME}/.bash_completion"
cd "/home/${EDITOR_USER_NAME}/project"
if [ ! -z "${EDITOR_CLONE}" ]; then
    git clone "${EDITOR_CLONE}" || true
fi

# Profile
touch /tmp/.versions
docker -v >> /tmp/.versions
docker-compose -v >> /tmp/.versions
echo ". /welcome.sh" >> "/home/${EDITOR_USER_NAME}/.bashrc"

# Extensions
if [ ! -z "${EDITOR_EXTENSIONS}" ]; then
    IFS=";"
    for EXTENSION in ${EDITOR_EXTENSIONS}; do
        code-server --install-extension "${EXTENSION}" || true
    done
fi

# Settings
EDITOR_LINE_ENDINGS="${EDITOR_LINE_ENDINGS:-LF}"
if [ "${EDITOR_LINE_ENDINGS}" != "CRLF" ]; then
    git config --global core.autocrlf false
    cat > /home/${EDITOR_USER_NAME}/.config/code-server/User/settings.json <<EOF
{
    "files.eol": "\n",
    "terminal.integrated.shell.linux": "/bin/bash",
    "update.enableWindowsBackgroundUpdates": false,
    "update.mode": "none"
}
EOF
fi

# Launch
EDITOR_PORT="${EDITOR_PORT:-8443}"
if [ ! -z "${EDITOR_PASSWORD}" ]; then
    export PASSWORD="${EDITOR_PASSWORD}"
    exec code-server --port "${EDITOR_PORT}" --allow-http
else
    exec code-server --port "${EDITOR_PORT}" --allow-http --no-auth
fi