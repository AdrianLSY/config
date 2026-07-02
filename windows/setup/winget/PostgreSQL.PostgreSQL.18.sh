#!/bin/bash
set -e

# Counterpart of macos/setup/brew/libpq.sh (psql/pg_dump/pg_restore, client only,
# no server). winget has no client-only package, so use the EDB installer's
# component flags via --override: commandlinetools only, server/pgAdmin/Stack
# Builder disabled (names per EDB's command_line_parameters docs). The override
# replaces winget's own silent flags, so pass the unattended-mode flags too.
# Major-pinned id: when brew's libpq moves majors, bump this filename + id together.
winget install --id "PostgreSQL.PostgreSQL.18" -e --accept-package-agreements --accept-source-agreements \
    --override "--mode unattended --unattendedmodeui none --disable-components server,pgAdmin,stackbuilder --enable-components commandlinetools"
