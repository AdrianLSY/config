#!/usr/bin/env bash

dir="$HOME/.config/rofi/clipboard"
theme='style'
limit=50
db="$HOME/.clipboard.sqlite"
table="c"
id_col="id"

# Prune clipboard history to only the latest $limit entries
sqlite3 "$db" "
DELETE FROM $table
WHERE $id_col NOT IN (
    SELECT $id_col FROM $table ORDER BY $id_col DESC LIMIT $limit
);
"

# Remove entries that are NOT valid UTF-8 (e.g., images/binary)
sqlite3 "$db" "SELECT $id_col, contents FROM $table;" | \
while IFS='|' read -r id contents; do
    # If contents is not valid UTF-8, delete from DB
    printf '%s' "$contents" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        sqlite3 "$db" "DELETE FROM $table WHERE $id_col = $id;"
    fi
done

# Show rofi menu and copy selected entry
wl-clipboard-history -l $limit \
  | rofi -dmenu -theme "${dir}/${theme}.rasi" -p "󰅎" \
  | sed 's/^[0-9]\+,//' \
  | awk 'NF' \
  | wl-copy
