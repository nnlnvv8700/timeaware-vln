#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE_DIR=""
DOWNLOAD_SCRIPT="${DOWNLOAD_MP_PY:-}"
PYTHON2_BIN="${PYTHON2_BIN:-python2}"
SHARED_ROOT="${SHARED_MP3D_ROOT:-${REPO_ROOT}/data/scene_datasets/mp3d}"
REPLACE=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install_mp3d_scenes.sh [options]

Options:
  --source DIR              Reuse an existing mp3d scene directory.
                            Expected layout: DIR/{scene}/{scene}.glb
  --download-script PATH    Path to Matterport's official download_mp.py.
  --shared-root DIR         Download target or canonical shared mp3d root.
                            Default: data/scene_datasets/mp3d
  --python2 BIN             Python 2.7 executable for download_mp.py.
                            Default: python2
  --replace                 Replace existing VLN-CE / IVLN-CE mp3d targets.
  -h, --help                Show this help message.

Examples:
  ./scripts/install_mp3d_scenes.sh --source /path/to/mp3d
  ./scripts/install_mp3d_scenes.sh --download-script ~/downloads/download_mp.py
EOF
}

die() {
  echo "[error] $*" >&2
  exit 1
}

count_glbs() {
  local root="$1"
  if [[ -d "${root}" ]]; then
    find -L "${root}" -mindepth 2 -maxdepth 2 -name '*.glb' | wc -l
  else
    echo 0
  fi
}

validate_mp3d_root() {
  local root="$1"
  local count
  count="$(count_glbs "${root}")"
  if (( count < 90 )); then
    die "MP3D root ${root} only has ${count} .glb files; expected at least 90"
  fi
  echo "[ok] MP3D root ${root} has ${count} .glb files"
}

ensure_parent() {
  mkdir -p "$1"
}

install_link() {
  local target="$1"
  local source="$2"
  local parent
  parent="$(dirname "${target}")"
  ensure_parent "${parent}"

  if [[ -L "${target}" ]]; then
    rm -f "${target}"
  elif [[ -d "${target}" ]]; then
    if [[ "${REPLACE}" -eq 1 ]]; then
      rm -rf "${target}"
    elif [[ -z "$(find "${target}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
      rmdir "${target}"
    else
      die "Target ${target} already exists and is not empty; rerun with --replace"
    fi
  elif [[ -e "${target}" ]]; then
    if [[ "${REPLACE}" -eq 1 ]]; then
      rm -f "${target}"
    else
      die "Target ${target} already exists; rerun with --replace"
    fi
  fi

  ln -s "${source}" "${target}"
  echo "[linked] ${target} -> ${source}"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --source)
      [[ "$#" -ge 2 ]] || die "--source requires a directory"
      SOURCE_DIR="$2"
      shift 2
      ;;
    --download-script)
      [[ "$#" -ge 2 ]] || die "--download-script requires a path"
      DOWNLOAD_SCRIPT="$2"
      shift 2
      ;;
    --shared-root)
      [[ "$#" -ge 2 ]] || die "--shared-root requires a directory"
      SHARED_ROOT="$2"
      shift 2
      ;;
    --python2)
      [[ "$#" -ge 2 ]] || die "--python2 requires an executable name"
      PYTHON2_BIN="$2"
      shift 2
      ;;
    --replace)
      REPLACE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

if [[ -n "${SOURCE_DIR}" && -n "${DOWNLOAD_SCRIPT}" ]]; then
  die "Use either --source or --download-script, not both"
fi

if [[ -z "${SOURCE_DIR}" && -z "${DOWNLOAD_SCRIPT}" ]]; then
  die "Provide --source or --download-script"
fi

MP3D_ROOT="${SOURCE_DIR:-${SHARED_ROOT}}"

if [[ -n "${SOURCE_DIR}" ]]; then
  validate_mp3d_root "${SOURCE_DIR}"
else
  [[ -f "${DOWNLOAD_SCRIPT}" ]] || die "download script not found: ${DOWNLOAD_SCRIPT}"
  command -v "${PYTHON2_BIN}" >/dev/null 2>&1 || die "python2 executable not found: ${PYTHON2_BIN}"
  mkdir -p "${SHARED_ROOT}"
  echo "[run] ${PYTHON2_BIN} ${DOWNLOAD_SCRIPT} --task habitat -o ${SHARED_ROOT}"
  "${PYTHON2_BIN}" "${DOWNLOAD_SCRIPT}" --task habitat -o "${SHARED_ROOT}"
  validate_mp3d_root "${SHARED_ROOT}"
fi

install_link "${REPO_ROOT}/vln_external/VLN-CE/data/scene_datasets/mp3d" "${MP3D_ROOT}"
install_link "${REPO_ROOT}/vln_external/IVLN-CE/data/scene_datasets/mp3d" "${MP3D_ROOT}"

echo
echo "[done] MP3D scenes are installed for both VLN-CE and IVLN-CE"
echo "[next] Verify with: ./scripts/check_native_baselines_data.sh"
