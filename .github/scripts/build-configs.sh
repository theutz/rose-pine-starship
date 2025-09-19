#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_JSON="./src/configs.json"
MODULE_DIR="./src/modules"
OUT_DIR="./example"
mkdir -p "$OUT_DIR"

# list of language modules (order preserved)
lang_modules=(c elixir elm golang haskell java julia nodejs nim rust scala python)

# read all configs into an array to avoid subshell issues
configs=$(jq -c '.[]' "$CONFIG_JSON")

for cfg in $configs; do
  name=$(jq -r '.name' <<<"$cfg")
  if [ -z "$name" ] || [ "$name" = "null" ]; then
    echo "Skipping invalid config: $cfg" >&2
    continue
  fi

  output="$OUT_DIR/${name}.toml"
  : > "$output"

  format_parts=()  # reset for each config

  # read modules as an array
  modules=($(jq -r '.modules[]' <<<"$cfg"))

  for mod in "${modules[@]}"; do
    if [ "$mod" = "languages" ]; then
      for lang in "${lang_modules[@]}"; do
        file="$MODULE_DIR/${lang}.toml"
        if [ -f "$file" ]; then
          cat "$file" >> "$output"
          echo >> "$output"
        else
          echo "Warning: $file not found, skipping" >&2
        fi
        format_parts+=("\$${lang}")
      done
    else
      file="$MODULE_DIR/${mod}"
      if [ -f "$file" ]; then
        cat "$file" >> "$output"
        echo >> "$output"
      else
        echo "Warning: $file not found, skipping" >&2
      fi
      format_parts+=("\$${mod}")
    fi
  done

  # join array into space-separated string
  format_line=$(IFS='\ \\n'; echo "${format_parts[*]}")

  # write format block
  cat >> "$output" <<EOF
format = """
${format_line} \
[󱞪](fg:iris)
"""
EOF

  echo "✅ Built $output"
done
