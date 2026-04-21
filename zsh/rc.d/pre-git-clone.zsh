# Git wrapper — auto-selects the correct GitHub account and SSH key before cloning
git() {
  if [[ "$1" != "clone" ]]; then
    command git "$@"
    return
  fi

  # Find GitHub URL in clone arguments
  local url=""
  local args=("$@")
  for arg in "${args[@]:1}"; do
    [[ "$arg" == -* ]] && continue
    if [[ "$arg" == *github.com* ]]; then
      url="$arg"
      break
    fi
  done

  # Non-GitHub clone — pass through
  if [[ -z "$url" ]]; then
    command git "$@"
    return
  fi

  local owner repo
  owner=$(echo "$url" | sed -nE 's|.*github\.com[:/]([^/]+)/.*|\1|p' | head -1)
  repo=$(echo "$url" | sed -nE 's|.*github\.com[:/][^/]+/([^/ .]+).*|\1|p' | head -1)

  if [[ -z "$owner" || -z "$repo" ]]; then
    command git "$@"
    return
  fi

  # Determine account
  local account=""
  case "$owner" in
    Adrian-LSY) account="Adrian-LSY" ;;
    AdrianLSY)  account="AdrianLSY" ;;
  esac

  # For orgs/other owners, check which account has push access
  if [[ -z "$account" ]]; then
    for try in Adrian-LSY AdrianLSY; do
      gh auth switch --user "$try" --hostname github.com 2>/dev/null
      local push
      push=$(gh api "repos/$owner/$repo" -q '.permissions.push // false' 2>/dev/null)
      if [[ "$push" == "true" ]]; then
        account="$try"
        break
      fi
    done
  fi

  [[ -z "$account" ]] && account="AdrianLSY"

  # Resolve SSH key and email
  local identity email signingkey
  case "$account" in
    Adrian-LSY)
      identity="$HOME/.ssh/adrian_rooftop_ed25519"
      email="adrian@rooftop.my"
      signingkey="~/.ssh/adrian_rooftop_ed25519.pub"
      ;;
    AdrianLSY)
      identity="$HOME/.ssh/sites_ad_p3_ed25519"
      email="adrianlow1998@gmail.com"
      signingkey="~/.ssh/sites_ad_p3_ed25519.pub"
      ;;
  esac

  # Switch gh auth
  gh auth switch --user "$account" --hostname github.com 2>/dev/null

  # Clone with the correct SSH key
  GIT_SSH_COMMAND="ssh -i $identity -o IdentitiesOnly=yes" command git "$@"
  local ret=$?

  if [[ $ret -eq 0 ]]; then
    # Determine clone target directory
    local target=""
    local found_url=0
    for arg in "${args[@]:1}"; do
      [[ "$arg" == -* ]] && continue
      if (( found_url )); then
        target="$arg"
        break
      fi
      [[ "$arg" == "$url" ]] && found_url=1
    done
    [[ -z "$target" ]] && target="$repo"

    # Configure the cloned repo and any submodules
    if [[ -d "$target" ]]; then
      local dir
      for dir in "$target" $(command git -C "$target" submodule foreach --recursive --quiet 'echo $toplevel/$sm_path' 2>/dev/null); do
        command git -C "$dir" config core.sshCommand "ssh -i $identity -o IdentitiesOnly=yes"
        command git -C "$dir" config user.name "Adrian Low"
        command git -C "$dir" config user.email "$email"
        command git -C "$dir" config user.signingkey "$signingkey"
        command git -C "$dir" config gpg.format ssh
        command git -C "$dir" config commit.gpgsign true
        command git -C "$dir" config tag.gpgsign true
        command git -C "$dir" config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
      done
      echo "Auto-configured for $account ($email)"
    fi
  fi

  return $ret
}
