#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_REPOSITORY="https://github.com/MartinDelophy/ai-video-editor.git"
readonly ICON_SHA256="f48d3caed336643923a96dbfeac991046cf39e4e9ea256683b8c46caa76b1683"
readonly FILE_CHOOSER_SHA256="f0cc087e00505308cdf826e9adbef8edf043da2d6430f4be5a6edc5ea98c9637"

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
tag="${LAZYCAT_TAG:-}"

if [[ -z "${tag}" ]]; then
  version="$(sed -nE 's/^version:[[:space:]]*"?([^"[:space:]]+)"?[[:space:]]*$/\1/p' "${project_root}/package.yml")"
  if [[ -z "${version}" ]]; then
    echo "Unable to read version from package.yml" >&2
    exit 1
  fi
  tag="v${version}"
fi

if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$ ]]; then
  echo "Unsupported upstream release tag: ${tag}" >&2
  exit 1
fi

printf '%s  %s\n' "${ICON_SHA256}" "${project_root}/icon.png" | sha256sum --check --status
printf '%s  %s\n' \
  "${FILE_CHOOSER_SHA256}" \
  "${project_root}/content/lazycat-injects/lzc-file-chooser-inject.js" | sha256sum --check --status

source_dir="$(mktemp -d "${TMPDIR:-/tmp}/timeline-studio-source.XXXXXX")"
cleanup() {
  rm -rf -- "${source_dir}"
}
trap cleanup EXIT

for attempt in 1 2 3; do
  rm -rf -- "${source_dir}"
  if GIT_TERMINAL_PROMPT=0 git clone \
    --depth=1 \
    --single-branch \
    --branch "${tag}" \
    "${UPSTREAM_REPOSITORY}" \
    "${source_dir}"; then
    break
  fi

  if [[ "${attempt}" -eq 3 ]]; then
    echo "Unable to clone ${UPSTREAM_REPOSITORY} at ${tag} after ${attempt} attempts" >&2
    exit 1
  fi

  sleep "$((attempt * 2))"
done

mkdir -p "${project_root}/content/dist" "${project_root}/dist-lpk"

(
  cd "${source_dir}"
  npm_config_fetch_retries=3 \
    npm_config_fetch_retry_maxtimeout=60000 \
    npm ci
  npm run build -- \
    --outDir "${project_root}/content/dist" \
    --emptyOutDir
)

test -s "${project_root}/content/dist/index.html"
