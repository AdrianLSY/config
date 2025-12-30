function ghu
    # Helper function to clean a single repo
    function _ghu_clean_repo
        set repo_path $argv[1]
        cd $repo_path

        # Determine main branch name
        set main_branch (basename (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) 2>/dev/null)
        if test -z "$main_branch"
            echo "  Skipping $repo_path (no origin/HEAD)"
            return
        end

        echo "Processing: $repo_path"

        # Fetch and prune
        git fetch --all --prune --quiet

        # Checkout main branch
        set current (git branch --show-current)
        if test "$current" != "$main_branch"
            git checkout $main_branch --quiet 2>/dev/null
            or git checkout -B $main_branch origin/$main_branch --quiet
        end

        # Pull latest (fast-forward or reset if needed)
        git pull --ff-only --quiet 2>/dev/null
        or git reset --hard origin/$main_branch --quiet

        # Delete stale branches (branches with gone remote)
        set stale (git branch -vv | grep ': gone]' | awk '{print $1}' | grep -v "^$main_branch\$")
        for branch in $stale
            echo "  Deleting stale branch: $branch"
            git branch -D $branch 2>/dev/null
        end

        # Delete local-only branches (no upstream, not main)
        for branch in (git branch --format='%(refname:short)')
            if test "$branch" != "$main_branch"
                if not git show-ref --verify --quiet "refs/remotes/origin/$branch"
                    echo "  Deleting local-only branch: $branch"
                    git branch -D $branch 2>/dev/null
                end
            end
        end
    end

    # Save starting directory
    set start_dir (pwd)
    set root_dir (git rev-parse --show-toplevel)

    # Process top-level repo
    _ghu_clean_repo $root_dir

    # Process all submodules recursively
    cd $root_dir
    for submodule in (git submodule foreach --recursive --quiet 'echo $toplevel/$sm_path')
        _ghu_clean_repo $submodule
    end

    # Return to starting directory
    cd $start_dir

    # Clean up helper function
    functions -e _ghu_clean_repo

    echo "Done!"
end
