#!/bin/bash
set -e

# psql (and pg_dump, pg_restore, etc.) ship in libpq — client only, no server.
# libpq is keg-only, so force-link it to put psql on the PATH.
brew install libpq
brew link --force libpq
