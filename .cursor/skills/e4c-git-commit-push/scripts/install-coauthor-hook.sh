#!/bin/bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
hook="$root/.git/hooks/prepare-commit-msg"
cat > "$hook" <<'EOF'
#!/bin/sh
# Strip Cursor/Claude co-author trailers injected by AI tools.
if [ -f "$1" ]; then
  sed -i '/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\.com/d' "$1" 2>/dev/null || \
    sed -i '' '/[Cc]o-[Aa]uthored-[Bb]y:.*cursoragent@cursor\.com/d' "$1" 2>/dev/null || true
  sed -i '/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\.com/d' "$1" 2>/dev/null || \
    sed -i '' '/[Cc]o-[Aa]uthored-[Bb]y:.*anthropic\.com/d' "$1" 2>/dev/null || true
  sed -i '/^[Mm]ade-with:.*[Cc]ursor/d' "$1" 2>/dev/null || \
    sed -i '' '/^[Mm]ade-with:.*[Cc]ursor/d' "$1" 2>/dev/null || true
fi
EOF
chmod +x "$hook"
echo "Installed: $hook"
