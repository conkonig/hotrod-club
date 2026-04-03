#!/bin/bash
set -euo pipefail

RAW_DIR="images_raw"
ASSETS_DIR="assets"
QUALITY="${WEBP_QUALITY:-80}"

if ! command -v cwebp >/dev/null 2>&1; then
  echo "cwebp is required but not installed."
  echo "Install it with: brew install webp"
  exit 1
fi

mkdir -p "$RAW_DIR"
mkdir -p "$ASSETS_DIR"

converted_any=false

make_target_path() {
  local source_file="$1"
  local base_name ext suffix candidate counter

  base_name="${source_file%.*}"
  base_name="${base_name##*/}"
  ext="${source_file##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
  candidate="${ASSETS_DIR}/${base_name}.webp"

  if [ ! -e "$candidate" ]; then
    printf '%s\n' "$candidate"
    return
  fi

  suffix="-from-${ext}"
  candidate="${ASSETS_DIR}/${base_name}${suffix}.webp"
  counter=2

  while [ -e "$candidate" ]; do
    candidate="${ASSETS_DIR}/${base_name}${suffix}-${counter}.webp"
    counter=$((counter + 1))
  done

  printf '%s\n' "$candidate"
}

while IFS= read -r -d '' file; do
  file="${file#./}"

  # Skip anything already inside the raw image archive folder.
  case "$file" in
    "$RAW_DIR"/*)
      continue
      ;;
  esac

  target="$(make_target_path "$file")"
  echo "Converting '$file' -> '$target'"

  cwebp -q "$QUALITY" "$file" -o "$target" >/dev/null
  mv "$file" "$RAW_DIR/"
  converted_any=true
done < <(find . -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0)

if [ "$converted_any" = false ]; then
  echo "No PNG or JPEG images found in the project root."
else
  echo "Done. WebP files were written to '$ASSETS_DIR/' and originals were moved to '$RAW_DIR/'."
fi
