#!/usr/bin/env bash
set -e

sudo snapper -c root create-config /
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
