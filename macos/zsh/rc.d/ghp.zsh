ghp() {
  local message="$*"
  local current_branch=$(git branch --show-current)

  if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
    git add . && git commit -m "$message" && git push
  else
    git add . && git commit -m "$message" && git push --set-upstream origin "$current_branch"
  fi
}
