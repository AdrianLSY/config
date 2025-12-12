#!/bin/bash
set -e

curl -fsSL https://get.pulumi.com | sh

fish_add_path /home/adrian/.pulumi/bin/
