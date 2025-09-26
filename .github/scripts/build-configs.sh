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
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

# read all configs into an array to avoid subshell issues
configs=$(jq -c '.[]' "$CONFIG_JSON")

for cfg in $configs; do
  name=$(jq -r '.name' <<<"$cfg")
  [ -z "$name" ] || [ "$name" = "null" ] && continue

  output="$OUT_DIR/$name"
  rm -rf "$output"
  mkdir -p "$output"

  # build modules array with defaults
  modules=()
  colours=()
  while read -r mod; do
    mname=$(jq -r '.name' <<<"$mod")
    mcolour=$(jq -r '.colour // "iris"' <<<"$mod")
    modules+=("$mname")
    colours+=("$mcolour")
  done < <(echo "$cfg" | jq -c '.modules[]')

  # build format_parts (still needs polish if you want prompt handling)
  format_parts=()
  for mod in "${modules[@]}"; do
    if [ "$mod" = "languages" ]; then
      for lang in "${lang_modules[@]}"; do
        format_parts+=("\$${lang}")
      done
    elif [ "$mod" = "prompt1" ]; then
      prompt="$prompt1"
    else
      format_parts+=("\$${mod}")
    fi
  done

  # iterate palettes
  for pal in "${palettes[@]}"; do
    outputp="$output/$pal.toml"
    : > "$outputp"

    format_line=$(printf "%s \\n" "${format_parts[@]}")
    cat > "$outputp" <<EOF
"\$schema" = 'https://starship.rs/config-schema.json'

format = """
${format_line} \
"""
EOF

    pal_file="$PALETTE_DIR/$pal"
    [ -f "$pal_file" ] && cat "$pal_file" >> "$outputp" || echo "Warning: $pal_file missing" >&2

    # append each module, replacing ACCENT with its colour
    for i in "${!modules[@]}"; do
      mod="${modules[$i]}"
      colour="${colours[$i]}"
      file="$MODULE_DIR/$mod"
      if [ -f "$file" ]; then
        sed "s/ACCENT/$colour/g" "$file" >> "$outputp"
        echo >> "$outputp"
      else
        echo "Warning: $file not found, skipping" >&2
      fi
    done
  done
done
