#!/bin/bash
set -e

# Set IINA as default video player
for ext in mp4 mkv avi mov webm flv wmv m4v mpg mpeg 3gp ts vob ogv m2ts; do
    duti -s com.colliderli.iina .$ext all
done

duti -s com.colliderli.iina public.movie all
duti -s com.colliderli.iina public.video all
