function ghp
    set -l message (string join " " $argv)
    set -l current_branch (git branch --show-current)

    # Check if upstream is already set
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null
        git add . && git commit -m "$message" && git push
    else
        git add . && git commit -m "$message" && git push --set-upstream origin $current_branch
    end
end
