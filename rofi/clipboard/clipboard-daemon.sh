#!/usr/bin/env bash

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
PRAGMA auto_vacuum = INCREMENTAL;
EOF
fi

# Enable incremental auto-vacuum for existing database
sqlite3 "$db" "PRAGMA auto_vacuum = INCREMENTAL;" 2>/dev/null

# Background process to vacuum database every minute
vacuum_daemon() {
    while true; do
        sleep 60
        sqlite3 "$db" "PRAGMA incremental_vacuum;" 2>/dev/null
    done
}

# Start vacuum daemon in background
vacuum_daemon &
VACUUM_PID=$!

# Function to insert clipboard content
insert_clipboard() {
    local content
    content="$(cat)"
    if [ -n "$content" ]; then
        # Escape single quotes for SQL
        content="$(echo "$content" | sed "s/'/''/g")"
        sqlite3 "$db" "INSERT INTO c (contents) VALUES ('$content');" 2>/dev/null
    fi
}

# Export function so wl-paste can use it
export -f insert_clipboard
export db

# Cleanup function to kill vacuum daemon on exit
cleanup() {
    kill $VACUUM_PID 2>/dev/null
}
trap cleanup EXIT

# Watch clipboard and insert new content
wl-paste -w bash -c 'insert_clipboard'
