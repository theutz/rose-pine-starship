#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_JSON="./src/configs.json"
MODULE_DIR="./src/modules"
OUT_DIR="./example"
mkdir -p "$OUT_DIR"

# list of language modules (order preserved)
lang_modules=(c elixir elm golang haskell java julia nodejs nim rust scala python)

# iterate each config object (preserves order)
jq -c '.[]' "$CONFIG_JSON" | while IFS= read -r cfg; do
  name=$(jq -r '.name' <<<"$cfg")
  if [ -z "$name" ] || [ "$name" = "null" ]; then
    echo "Skipping invalid config: $cfg" >&2
    continue
  fi

  output="$OUT_DIR/${name}.toml"
  : > "$output"

  # accumulate format tokens (literal $var strings)
  format_parts=()

  # iterate modules in order
  jq -r '.modules[]' <<<"$cfg" | while IFS= read -r mod; do
    if [ "$mod" = "languages" ]; then
        if [ -f "$mod" ]; then
          cat "$mod" >> "$output"
          printf '\n' >> "$output"
        else
          echo "Warning: $mod not found, skipping" >&2
        fi
      for lang in "${lang_modules[@]}"; do
        format_parts+=("\$${lang}")
      done
    else
      file="$MODULE_DIR/${mod}.toml"
      if [ -f "$file" ]; then
        cat "$file" >> "$output"
        printf '\n' >> "$output"
      else
        echo "Warning: $file not found, skipping" >&2
      fi
      format_parts+=("\$${mod}")
    fi
  done

  # join the format parts into a single space-separated string
  format_line=$(IFS=' '; echo "${format_parts[*]}")

  # append the format block (safe heredoc inside script — not YAML)
  cat >> "$output" <<EOF
[format]
format = """
${format_line} \\
"""
EOF

  echo "✅ Built $output"
done

