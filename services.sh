#!/usr/bin/dumb-init /bin/sh

usermod -aG docker editor

/su-exec editor code-server --port 8443 --allow-http --no-auth &

dockerd --storage-driver vfs