_ghu_process_repo() {
  local repo_path=$1
  cd "$repo_path" 2>/dev/null || return

  local main_branch
  main_branch=$(git config --get init.defaultBranch 2>/dev/null)
  if [[ -z "$main_branch" ]]; then
    main_branch=$(basename "$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)" 2>/dev/null)
  fi
  if [[ -z "$main_branch" ]]; then
    echo "  Skipping $repo_path (no origin/HEAD)"
    return
  fi

  echo "Processing: $repo_path"

  git fetch origin --prune --quiet 2>/dev/null

  local current
  current=$(git branch --show-current 2>/dev/null)
  if [[ "$current" != "$main_branch" ]]; then
    git checkout "$main_branch" --quiet 2>/dev/null \
      || git checkout -B "$main_branch" "origin/$main_branch" --quiet 2>/dev/null
  fi

  git merge --ff-only "origin/$main_branch" --quiet 2>/dev/null \
    || git reset --hard "origin/$main_branch" --quiet 2>/dev/null

  local branch_name tracking
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads 2>/dev/null | while IFS=' ' read -r branch_name tracking; do
    [[ "$branch_name" == "$main_branch" ]] && continue
    if [[ "$tracking" == "[gone]" ]] || ! git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null; then
      echo "  Deleting branch: $branch_name"
      git branch -D "$branch_name" 2>/dev/null
    fi
  done
}

ghu() {
  local start_dir=$(pwd)
  local root_dir
  root_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository"
    return 1
  }

  _ghu_process_repo "$root_dir"

  cd "$root_dir"
  local submodules=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && submodules+=("$line")
  done < <(git submodule foreach --recursive --quiet 'echo $toplevel/$sm_path' 2>/dev/null)

  if (( ${#submodules[@]} > 0 )); then
    for submodule in "${submodules[@]}"; do
      ( _ghu_process_repo "$submodule" ) &
    done
    wait
  fi

  cd "$start_dir"
  echo "Done!"
}
