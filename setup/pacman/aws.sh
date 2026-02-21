#!/bin/bash
set -e

sudo pacman -S --noconfirm aws-cli-v2

aws configure set region ap-southeast-5
