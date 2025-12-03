function ghp
    set -l message (string join " " $argv)
    git add . && git commit -m "$message" && git push
end
