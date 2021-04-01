#!/bin/bash
set -ex

# This script fetches swarm join tokens from a remote server, via SSH
# https://www.terraform.io/docs/providers/external/data_source.html#processing-json-in-shell-scripts

# Parse existing /dev/stdin as JSON and into shell variables.
[ ! -t 0 ] && eval "$(jq -r '@sh "SSH_HOST=\(.host) SSH_USER=\(.user) PRIVATE_KEY=\(.private_key)"')"

SSH_HOST=${SSH_HOST:-""}
SSH_USER=${SSH_USER:-""}
PRIVATE_KEY=${PRIVATE_KEY:-""}

# @TODO: Normal bash arguments & options would be nice to have.
if [ -z "$SSH_HOST" ]; then
  echo "Usage: HOST=remote.domain $0" >&2
  exit 1
fi

# LogLevel error is to suppress any host warnings. The others are necessary if
# working with development servers with self-signed certificates.
# @TODO: Don't ignore SSH_OPTIONS from the environment
SSH_OPTIONS=()
SSH_OPTIONS+=("-o BatchMode=yes")
SSH_OPTIONS+=("-o ConnectTimeout=3")
SSH_OPTIONS+=("-o StrictHostKeyChecking=no")
SSH_OPTIONS+=("-o UserKnownHostsFile=/dev/null")

# If provided, set the identity_file opt
if [ -n "$PRIVATE_KEY" ]; then
  SSH_OPTIONS+=("-i /dev/stdin")
fi

get_token() {
  echo "$PRIVATE_KEY" | ssh "${SSH_OPTIONS[@]}" "${SSH_USER:+${SSH_USER}@}${SSH_HOST}" docker swarm join-token -q "$1"
}

manager_token="$(get_token manager)"
worker_token="$(get_token worker)"

if [ -z "$manager_token" ] || [ -z "$worker_token" ]; then
  echo "ERROR: Unable to resolve tokens"
  exit 1
fi

# Safely produce a properly quoted and escaped, valid JSON object.
# https://www.terraform.io/docs/providers/external/data_source.html
jq -cen \
  --arg manager "$manager_token" \
  --arg worker "$worker_token" \
  '{ manager: $manager, worker: $worker }'
