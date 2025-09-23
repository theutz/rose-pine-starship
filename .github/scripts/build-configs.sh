#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_JSON="./src/configs.json"
MODULE_DIR="./src/modules"
PALETTE_DIR="./src/themes"
OUT_DIR="./examples"
mkdir -p "$OUT_DIR"

# TODO: These are some things you may need to change as well, for example adding a
# new prompt or languages

# list of language modules (order preserved)
lang_modules=(c elixir elm golang haskell java julia nodejs nim rust scala python)

# Add prompts here
prompt1="[󱞪](fg:iris) \\"

palettes=("rose-pine", "rose-pine-moon", "rose-pine-dawn")

# read all configs into an array to avoid subshell issues
configs=$(jq -c '.[]' "$CONFIG_JSON")

for cfg in $configs; do
  name=$(jq -r '.name' <<<"$cfg")
  if [ -z "$name" ] || [ "$name" = "null" ]; then
    echo "Skipping invalid config: $cfg" >&2
    continue
  fi

  output="$OUT_DIR/${name}"
  : > "$output"

  format_parts=()  # reset for each config
  modules=($(jq -r '.modules[]' <<<"$cfg"))

  prompt=""
  # build format_parts array without touching output yet
  for mod in "${modules[@]}"; do
    if [ "$mod" = "languages" ]; then
      for lang in "${lang_modules[@]}"; do
        format_parts+=("\$${lang}")
      done
    # TODO: this can def be simplified with regex (I don't think those words have ever
    # been said in that order, simple and regex, hell nah)
    elif [ "$mod" = "prompt1" ]; then
      prompt=prompt1
    else
      format_parts+=("\$${mod}")
    fi
  done

  # write format block FIRST
  format_line=$(printf "%s \\n" "${format_parts[@]}")
  cat > "$output" <<EOF
"\$schema" = 'https://starship.rs/config-schema.json'
  
format = """
${format_line} \
"""
EOF


  # Add palette here
  for pal in palettes; do
    output="${output}-${pal}.toml"

    pal_file="$PALETTE_DIR/${pal}"
    if [ -f "$pal_file" ]; then
      cat "$file" >> "$output"
      echo >> "$output"
    else
      echo "Warning: $pal_file not found, skipping" >&2
    fi
    
    # then append each module content
    for mod in "${modules[@]}"; do
      file="$MODULE_DIR/${mod}"
      if [ -f "$file" ]; then
        cat "$file" >> "$output"
        echo >> "$output"
      else
        echo "Warning: $file not found, skipping" >&2
      fi
    done
  done

  echo "✅ Built $output"
done
