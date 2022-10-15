#!/bin/bash

set -e

rm -f /home/ruby/myapp-backend/tmp/pids/server.pid

exec "$@"
