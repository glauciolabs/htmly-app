#!/usr/bin/env bash
set -euo pipefail

if [[ "${DOCKER_OPTIONS:-build_and_push}" == "disable_docker" ]]; then
  echo "Docker build disabled (DOCKER_OPTIONS=disable_docker)."
  exit 0
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
info_root="${root_dir}/info.yaml"
info_container="${root_dir}/container/htmly/info.yaml"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required." >&2
  exit 1
fi

if [[ ! -f "${info_root}" || ! -f "${info_container}" ]]; then
  echo "info.yaml files not found." >&2
  exit 1
fi

version="$(yq -r '.app.version' "${info_root}")"
repository="$(yq -r '.app.container.repository' "${info_container}")"
tag="$(yq -r '.app.container.tag' "${info_container}")"
platforms="$(yq -r '.app.container.platform // "linux/amd64"' "${info_container}")"
vcs_ref="$(git -C "${root_dir}" rev-parse HEAD)"
build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

context="${root_dir}/container/htmly"
dockerfile="${context}/Dockerfile"

push_flag=false
if [[ "${DOCKER_OPTIONS}" == "build_and_push" ]]; then
  push_flag=true
fi

echo "Building image ${repository}:${tag} (HTMLY_VERSION=${version}) push=${push_flag}"

docker buildx build "${context}" \
  -f "${dockerfile}" \
  --platform "${platforms}" \
  --build-arg HTMLY_VERSION="${version}" \
  --build-arg VCS_REF="${vcs_ref}" \
  --build-arg BUILD_DATE="${build_date}" \
  -t "${repository}:${tag}" \
  -t "${repository}:sha-${vcs_ref:0:7}" \
  --push="${push_flag}"

echo "Build completed."
