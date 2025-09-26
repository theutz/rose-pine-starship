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

palettes=("rose-pine" "rose-pine-moon" "rose-pine-dawn")

# Hard reset everything
rm -rf OUT_DIR
mkdir OUT_DIR

# read all configs into an array to avoid subshell issues
configs=$(jq -c '.[]' "$CONFIG_JSON")

for cfg in $configs; do
  name=$(jq -r '.name' <<<"$cfg")
  if [ -z "$name" ] || [ "$name" = "null" ]; then
    echo "Skipping invalid config: $cfg" >&2
    continue
  fi

  output="$OUT_DIR/${name}"

  rm -rf "$output"
  mkdir "$output"

  format_parts=()  # reset for each config
  jq -c '.modules[]' "$CONFIG_JSON" | while read -r mod; do
    name=$(jq -r '.name' <<<"$mod")
    colour=$(jq -r '.colour // "iris"' <<<"$mod")

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

  # Add palette here
  for pal in "${palettes[@]}"; do
    outputp="${output}/${pal}.toml"
    : > "$outputp"

    # write format block FIRST
    format_line=$(printf "%s \\n" "${format_parts[@]}")
    cat > "$outputp" <<EOF
"\$schema" = 'https://starship.rs/config-schema.json'
  
format = """
${format_line} \
"""
EOF


    pal_file="$PALETTE_DIR/${pal}"
    if [ -f "$pal_file" ]; then
      cat "$pal_file" >> "$outputp"
      echo >> "$outputp"
    else
      echo "Warning: $pal_file not found, skipping" >&2
    fi
    
    # then append each module content
    for mod in "${modules[@]}"; do
      file="$MODULE_DIR/${mod}"
      if [ -f "$file" ]; then
        sed "s/ACCENT/$colour/g" "$file" >> "$outputp"
        echo >> "$outputp"
      else
        echo "Warning: $file not found, skipping" >&2
      fi
    done
  done

  echo "✅ Built $outputp"
done
