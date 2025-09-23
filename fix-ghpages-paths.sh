#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
FILES=(
  "$ROOT/index.html"
  "$ROOT/404.html"
  "$ROOT/assets/index-"*.js
  "$ROOT/assets/index-"*.css
)

echo "Fixing ${#FILES[@]} files..."
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue

  # 1) Core asset dirs: "/assets|/icons|/fonts|/models|/shaders" → "./..."
  perl -0777 -i -pe 's#\"/(assets|icons|fonts|models|shaders)/#\"./$1/#g' "$f"
  perl -0777 -i -pe 's#\x27/(assets|icons|fonts|models|shaders)/#\x27./$1/#g' "$f"

  # 2) Top-level images: "/foo.png" → "./foo.png"
  perl -0777 -i -pe 's#\"/([A-Za-z0-9._-]+\.(png|jpg|jpeg|gif|svg|webp|ico))#\"./$1#g' "$f"
  perl -0777 -i -pe 's#\x27/([A-Za-z0-9._-]+\.(png|jpg|jpeg|gif|svg|webp|ico))#\x27./$1#g' "$f"

  # 3) CSS font urls: url(/fonts/...) → url(./fonts/...)
  perl -0777 -i -pe 's#url\(\s*/(fonts/)#url(./$1#g' "$f"

  # 4) Shader fetch normalizations - fix the template literal pattern causing double paths
  # Pattern: fetch(`./shaders/${filename}`) where filename gets prepended with "shaders/"
  perl -0777 -i -pe 's#fetch\(\s*`\./shaders/\$\{([^}]+)\}`#fetch(`./shaders/\${$1}`)#g' "$f"
  perl -0777 -i -pe 's#fetch\(\s*`shaders/\$\{([^}]+)\}`#fetch(`./shaders/\${$1}`)#g' "$f"
  # Standard fetch patterns
  perl -0777 -i -pe 's#fetch\(\s*\"shaders/#fetch(\"./shaders/#g' "$f"
  perl -0777 -i -pe "s#fetch\\(\\s*'shaders/#fetch('./shaders/#g" "$f"
  # Fix variables that might contain "shaders/" prefix getting doubled up  
  perl -0777 -i -pe 's#\./shaders/shaders/#./shaders/#g' "$f"
  perl -0777 -i -pe 's#shaders/shaders/#shaders/#g' "$f"

  # 5) If bundle used bare shader filenames, prefix them
  perl -0777 -i -pe 's#(?<![A-Za-z0-9_./-])(fileInstance|nodeSphere|lineRenderer)\.(vert|frag)#./shaders/$1.$2#g' "$f"

done

echo "Verify:"
grep -RnoE "['\"]/((assets|icons|fonts|models|shaders))/" "$ROOT" | head -100 || true
grep -RnoE "url\(\s*/fonts/" "$ROOT" | head -100 || true
grep -RnoE "['\"]/[^'\"()]+\.(png|jpg|jpeg|gif|svg|webp|ico)" "$ROOT" | head -100 || true
grep -RnoE "shaders/shaders|fetch\(\s*['\"\`]\.?/shaders/" "$ROOT" | head -100 || true
echo "Done."