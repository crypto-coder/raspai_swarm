#! /usr/bin/env sh
set -e

echo 'Checking ulimit during execution'
ulimit -l

DEFAULT_MODULE_NAME=llama_cpp.server.app
MODULE_NAME=${MODULE_NAME:-$DEFAULT_MODULE_NAME}
CONSTRUCTOR_NAME=${CONSTRUCTOR_NAME:-create_app}
export APP_MODULE=${APP_MODULE:-"$MODULE_NAME:$CONSTRUCTOR_NAME"}

HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8080}
LOG_LEVEL=${LOG_LEVEL:-info}

# Start Uvicorn with live reload
exec uvicorn --reload --host $HOST --port $PORT --log-level $LOG_LEVEL --factory "$APP_MODULE"