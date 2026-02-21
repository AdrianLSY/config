function ghu
    set start_dir (pwd)
    set root_dir (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo "Not in a git repository"
        return 1
    end

    # Process top-level repo first (sequentially, for cleaner output)
    _ghu_process_repo $root_dir

    # Get list of submodules and process in parallel
    cd $root_dir
    set submodules (git submodule foreach --recursive --quiet 'echo $toplevel/$sm_path' 2>/dev/null)

    if test (count $submodules) -gt 0
        # Process submodules in parallel using background jobs
        for submodule in $submodules
            fish -c "_ghu_process_repo $submodule" &
        end
        # Wait for all background jobs
        wait
    end

    cd $start_dir
    echo "Done!"
end

function _ghu_process_repo
    set repo_path $argv[1]
    cd $repo_path 2>/dev/null
    or return

    # Determine main branch name (fast path: check local config first)
    set main_branch (git config --get init.defaultBranch 2>/dev/null)
    if test -z "$main_branch"
        set main_branch (basename (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) 2>/dev/null)
    end
    if test -z "$main_branch"
        echo "  Skipping $repo_path (no origin/HEAD)"
        return
    end

    echo "Processing: $repo_path"

    # Fetch with prune (single network call)
    git fetch origin --prune --quiet 2>/dev/null

    # Switch to main branch if needed
    set current (git branch --show-current 2>/dev/null)
    if test "$current" != "$main_branch"
        git checkout $main_branch --quiet 2>/dev/null
        or git checkout -B $main_branch origin/$main_branch --quiet 2>/dev/null
    end

    # Fast-forward or reset to origin
    git merge --ff-only origin/$main_branch --quiet 2>/dev/null
    or git reset --hard origin/$main_branch --quiet 2>/dev/null

    # Get branches to delete in one pass
    set branches_to_delete
    for branch in (git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads 2>/dev/null)
        set parts (string split ' ' $branch)
        set branch_name $parts[1]
        set tracking $parts[2]

        # Skip main branch
        test "$branch_name" = "$main_branch"; and continue

        # Delete if gone or no upstream
        if test "$tracking" = "[gone]"
            set -a branches_to_delete $branch_name
        else if not git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null
            set -a branches_to_delete $branch_name
        end
    end

    # Batch delete branches
    for branch in $branches_to_delete
        echo "  Deleting branch: $branch"
        git branch -D $branch 2>/dev/null
    end
end
