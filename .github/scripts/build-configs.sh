#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_JSON="./src/configs.json"
MODULE_DIR="./src/modules"
OUT_DIR="./example"
mkdir -p "$OUT_DIR"

# list of language modules (order preserved)
lang_modules=(c elixir elm golang haskell java julia nodejs nim rust scala python)

# iterate each config object
jq -c '.[]' "$CONFIG_JSON" | while IFS= read -r cfg; do
  name=$(jq -r '.name' <<<"$cfg")
  if [ -z "$name" ] || [ "$name" = "null" ]; then
    echo "Skipping invalid config: $cfg" >&2
    continue
  fi

  output="$OUT_DIR/${name}.toml"
  : > "$output"

  format_parts=()  # reset for each config

  # iterate modules listed in the config
  jq -r '.modules[]' <<<"$cfg" | while IFS= read -r mod; do
    if [ "$mod" = "languages" ]; then
      # expand all language modules
      for lang in "${lang_modules[@]}"; do
        file="$MODULE_DIR/${lang}.toml"
        if [ -f "$file" ]; then
          cat "$file" >> "$output"
          printf '\n' >> "$output"
        else
          echo "Warning: $file not found, skipping" >&2
        fi
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

  # join format parts into a string for the TOML
  format_line=$(IFS=' '; echo "${format_parts[*]}")

  cat >> "$output" <<EOF
format = """
${format_line} \
[󱞪](fg:iris)
"""
EOF

  echo "✅ Built $output"
done
