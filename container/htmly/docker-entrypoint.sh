#!/bin/sh
set -eu

CONTENT_DIR="${CONTENT_DIR:-/var/www/html/content}"
GIT_CONTENT_BRANCH="${GIT_CONTENT_BRANCH:-main}"
GIT_CONTENT_SYNC_INTERVAL="${GIT_CONTENT_SYNC_INTERVAL:-60}"
GIT_CONTENT_USER="${GIT_CONTENT_USER:-HTMLy}"
GIT_CONTENT_EMAIL="${GIT_CONTENT_EMAIL:-htmly@local}"
GIT_CONTENT_SCM="${GIT_CONTENT_SCM:-generic}"
GIT_CONTENT_SSH_KEY_B64="${GIT_CONTENT_SSH_KEY_B64:-}"
GIT_CONTENT_HTTP_USER="${GIT_CONTENT_HTTP_USER:-}"

if [ -n "${GIT_CONTENT_REPO:-}" ]; then
  repo_url="$GIT_CONTENT_REPO"
  if [ -n "${GIT_CONTENT_HTTP_TOKEN:-}" ]; then
    case "$repo_url" in
      https://*@*)
        repo_url="$(printf '%s' "$repo_url" | sed "s#^https://\\([^/@]*\\)@#https://\\1:${GIT_CONTENT_HTTP_TOKEN}@#")"
        ;;
      https://*)
        if [ -n "$GIT_CONTENT_HTTP_USER" ]; then
          repo_url="$(printf '%s' "$repo_url" | sed "s#^https://#https://${GIT_CONTENT_HTTP_USER}:${GIT_CONTENT_HTTP_TOKEN}@#")"
        else
          repo_url="$(printf '%s' "$repo_url" | sed "s#^https://#https://${GIT_CONTENT_HTTP_TOKEN}@#")"
        fi
        ;;
    esac
  fi

  if [ -n "${GIT_CONTENT_SSH_KEY_B64:-}" ] || [ -n "${GIT_CONTENT_SSH_KEY:-}" ]; then
    mkdir -p "$HOME/.ssh"
    if [ -n "${GIT_CONTENT_SSH_KEY_B64:-}" ]; then
      printf '%s' "$GIT_CONTENT_SSH_KEY_B64" | tr -d '\r' | base64 -d > "$HOME/.ssh/id_rsa"
    else
      printf '%s' "$GIT_CONTENT_SSH_KEY" | tr -d '\r' > "$HOME/.ssh/id_rsa"
    fi
    chmod 600 "$HOME/.ssh/id_rsa"
    if [ -n "${GIT_CONTENT_KNOWN_HOSTS:-}" ]; then
      printf '%s\n' "$GIT_CONTENT_KNOWN_HOSTS" > "$HOME/.ssh/known_hosts"
      chmod 600 "$HOME/.ssh/known_hosts"
      export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_rsa -o UserKnownHostsFile=$HOME/.ssh/known_hosts"
    else
      export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    fi
  fi

  if [ -d "$CONTENT_DIR/.git" ]; then
    git -C "$CONTENT_DIR" fetch --prune origin
    git -C "$CONTENT_DIR" checkout "$GIT_CONTENT_BRANCH"
    git -C "$CONTENT_DIR" reset --hard "origin/$GIT_CONTENT_BRANCH"
  else
    rm -rf "$CONTENT_DIR"
    git clone --branch "$GIT_CONTENT_BRANCH" "$repo_url" "$CONTENT_DIR"
  fi

  if [ "${GIT_CONTENT_AUTO_PUSH:-true}" = "true" ]; then
    (
      while true; do
        sleep "$GIT_CONTENT_SYNC_INTERVAL"
        git -C "$CONTENT_DIR" add -A
        if ! git -C "$CONTENT_DIR" diff --cached --quiet; then
          git -C "$CONTENT_DIR" -c user.name="$GIT_CONTENT_USER" -c user.email="$GIT_CONTENT_EMAIL" \
            commit -m "Auto-sync $(date -u +%Y-%m-%dT%H:%M:%SZ)"
          git -C "$CONTENT_DIR" push "$repo_url" "HEAD:$GIT_CONTENT_BRANCH"
        fi
      done
    ) &
  fi

  (
    while true; do
      sleep 3600
      git -C "$CONTENT_DIR" fetch origin "$GIT_CONTENT_BRANCH"
      git -C "$CONTENT_DIR" reset --hard "origin/$GIT_CONTENT_BRANCH"
    done
  ) &

  config_repo_dir="$CONTENT_DIR/config"
  mkdir -p "$config_repo_dir"
  if [ -d "/var/www/html/config" ] && [ ! -L "/var/www/html/config" ]; then
    cp -n /var/www/html/config/* "$config_repo_dir/" 2>/dev/null || true
    rm -rf /var/www/html/config
  fi
  if [ ! -L "/var/www/html/config" ]; then
    ln -s "$config_repo_dir" /var/www/html/config
  fi

  themes_repo_dir="$CONTENT_DIR/themes"
  mkdir -p "$themes_repo_dir"
  if [ -d "/var/www/html/themes" ] && [ ! -L "/var/www/html/themes" ]; then
    cp -a /var/www/html/themes/. "$themes_repo_dir/" 2>/dev/null || true
    rm -rf /var/www/html/themes
  fi
  if [ ! -L "/var/www/html/themes" ]; then
    ln -s "$themes_repo_dir" /var/www/html/themes
  fi
fi

content_root="/var/www/html/content"
mkdir -p "$content_root/data" \
  "$content_root/data/category" \
  "$content_root/data/field" \
  "$content_root/data/frontpage" \
  "$content_root/images" \
  "$content_root/images/thumbnails" \
  "$content_root/comments"

if [ ! -f "$content_root/data/search.json" ]; then
  printf '[]' > "$content_root/data/search.json"
fi
if [ ! -f "$content_root/data/views.json" ]; then
  printf '[]' > "$content_root/data/views.json"
fi
if [ ! -f "$content_root/data/menu.json" ]; then
  printf '"[]"' > "$content_root/data/menu.json"
else
  MENU_FILE="$content_root/data/menu.json" php -r '
$file = getenv("MENU_FILE");
$raw = file_get_contents($file);
if ($raw === false) {
  exit(0);
}
$trim = ltrim($raw);
if ($trim === "") {
  file_put_contents($file, "\"[]\"");
  exit(0);
}
$first = $trim[0];
if ($first === "[" || $first === "{") {
  file_put_contents($file, json_encode($raw, JSON_UNESCAPED_UNICODE));
}
'
fi
if [ ! -f "$content_root/data/tags.lang" ]; then
  php -r 'echo serialize([]);' > "$content_root/data/tags.lang"
fi
if [ ! -f "$content_root/data/frontpage/frontpage.md" ]; then
  printf '' > "$content_root/data/frontpage/frontpage.md"
fi
for field in post page subpage profile; do
  if [ ! -f "$content_root/data/field/${field}.json" ]; then
    printf '[]' > "$content_root/data/field/${field}.json"
  fi
done


exec "$@"
