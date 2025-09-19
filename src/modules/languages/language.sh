#!/usr/bin/env bash

# Add languages with a symbol here
declare -A languages=(
  [c]=" "
  [elixir]=" "
  [elm]=" "
  [golang]=" "
  [haskell]=" "
  [java]=" "
  [julia]=" "
  [nodejs]="󰎙 "
  [nim]="󰆥 "
  [rust]=" "
  [scala]=" "
  [python]=" "
)
# From root dir of git to modules
output="./src/modules/language"
echo "" > $output

for lang in "${!languages[@]}"; do
  symbol=${languages[$lang]}
  cat >> $output <<EOF
[$lang]
style = "bg:overlay fg:pine"
format = "[](fg:overlay)[$symbol\$version](\$style)[](fg:overlay) "
disabled = false
symbol = "$symbol"

EOF
done
