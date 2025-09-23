#!/usr/bin/env bash

set -euo pipefail

# Rewrite root-absolute asset paths to relative and fix shader filenames

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

shopt -s nullglob
FILES=(
  "$ROOT_DIR/index.html"
  "$ROOT_DIR/404.html"
  "$ROOT_DIR/assets/index-"*.js
)

echo "Fixing paths in ${#FILES[@]} files..."

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue

  # Count before
  before_root=$(grep -Eo "['\"]/(icons|models|shaders|assets|fonts)/" "$f" | wc -l | tr -d ' ' || true)
  before_shaders=$(grep -Eo "(^|[^A-Za-z0-9_./-])(fileInstance|nodeSphere|lineRenderer)\.(vert|frag)" "$f" | wc -l | tr -d ' ' || true)

  # Replace quoted root-absolute to relative (handle ' and " separately to avoid regex class issues)
  perl -0777 -i -pe 's#\"/(icons|models|shaders|assets|fonts)/#\"./$1/#g' "$f"
  perl -0777 -i -pe 's#\x27/(icons|models|shaders|assets|fonts)/#\x27./$1/#g' "$f"

  # Replace bare shader filenames to ./shaders/<name>.<ext>
  perl -0777 -i -pe 's#(?<![A-Za-z0-9_./-])(fileInstance|nodeSphere|lineRenderer)\.(vert|frag)#./shaders/$1.$2#g' "$f"

  # Count after
  after_root=$(grep -Eo "['\"]/(icons|models|shaders|assets|fonts)/" "$f" | wc -l | tr -d ' ' || true)
  after_shaders=$(grep -Eo "(^|[^A-Za-z0-9_./-])(fileInstance|nodeSphere|lineRenderer)\.(vert|frag)" "$f" | wc -l | tr -d ' ' || true)

  echo "$(basename "$f"): root-absolute ${before_root} -> ${after_root}; shader names ${before_shaders} -> ${after_shaders}"
done

echo
echo "Remaining root-absolute asset refs (should be none):"
grep -nE "['\"]/(icons|models|shaders|assets|fonts)/" "${FILES[@]}" || true

echo
echo "Remaining bare shader filenames (should be none):"
grep -nE "(^|[^A-Za-z0-9_./-])(fileInstance|nodeSphere|lineRenderer)\.(vert|frag)" "${FILES[@]}" || true

echo
echo "Done."


