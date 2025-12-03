#!/usr/bin/env bash

dir="$HOME/.config/rofi/clipboard"
theme='style'
limit=20
db="$HOME/.clipboard.sqlite"

# Initialize database if it doesn't exist
if [ ! -f "$db" ]; then
    sqlite3 "$db" <<EOF
CREATE TABLE c (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, contents text);
CREATE INDEX IF NOT EXISTS idx_id ON c(id DESC);
CREATE TRIGGER rotate_rows AFTER INSERT ON c
BEGIN
    DELETE FROM c WHERE id <= (SELECT id FROM c ORDER BY id DESC LIMIT 1000, 1);
END;
EOF
fi

# Get preview list with optimized query
get_preview_list() {
    sqlite3 -separator "," "$db" "
    SELECT id, REPLACE(SUBSTR(contents, 1, 200), '
', ' ')
    FROM c
    WHERE id IN (SELECT MAX(id) FROM c GROUP BY contents)
    ORDER BY id DESC
    LIMIT $limit
    "
}

# Get full content by ID
get_content() {
    sqlite3 "$db" "SELECT contents FROM c WHERE id = $1"
}

# Show preview menu and get selected ID
selected_id=$(get_preview_list \
  | sed 's/^\([0-9]\+\),\(.*\)$/[\1] \2/' \
  | rofi -dmenu -theme "${dir}/${theme}.rasi" -p "󰅎" \
  | sed 's/^\[\([0-9]\+\)\].*/\1/')

# Fetch and paste full content for selected ID
if [ -n "$selected_id" ]; then
  get_content "$selected_id" | wl-copy
fi
