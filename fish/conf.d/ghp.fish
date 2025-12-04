function ghp
    set -l message (string join " " $argv)
    set -l current_branch (git branch --show-current)
    git add . && git commit -m "$message" && git push --set-upstream origin $current_branch
end
