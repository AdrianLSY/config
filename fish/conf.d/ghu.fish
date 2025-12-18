function ghu
    set main_branch (basename (git symbolic-ref refs/remotes/origin/HEAD))
    set current (git branch --show-current)

    if test "$current" != "$main_branch"
        git checkout $main_branch
    end

    git fetch --prune --recurse-submodules=on-demand --jobs=128
    set stale (git branch -vv | grep ': gone]' | awk '{print $1}' | grep -v "^$main_branch\$")

    if test (count $stale) -gt 0
        echo $stale | tr ' ' '\n' | xargs -r git branch -d
    end

    git pull --recurse-submodules --jobs=128
end
