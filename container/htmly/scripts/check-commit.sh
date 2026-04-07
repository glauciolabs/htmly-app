#!/bin/sh
set -eu

CONTENT_DIR="${CONTENT_DIR:-/var/www/html/content}"
GIT_CONTENT_BRANCH="${GIT_CONTENT_BRANCH:-main}"

cd "$CONTENT_DIR"
remote_commit=$(git ls-remote origin "$GIT_CONTENT_BRANCH" | awk '{print $1}' | head -n 1)
local_commit=$(git rev-parse HEAD)

printf "local=%s remote=%s\n" "$local_commit" "$remote_commit" >&2

if [ "$remote_commit" != "$local_commit" ]; then
  exit 1
fi

exit 0
