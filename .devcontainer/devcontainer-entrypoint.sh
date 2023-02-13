#!/usr/bin/env bash

set -eu

USER="$(whoami)"
sudo chown -R "${USER}" "/home/${USER}/.vscode-server"

exec "$@"
