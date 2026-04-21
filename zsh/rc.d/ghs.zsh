ghs() {
  if (( $# != 1 )); then
    echo "Usage: ghs <Adrian-LSY|AdrianLSY>"
    return 1
  fi

  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not found"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: not inside a git repository"
    return 1
  fi

  local target=$1

  if ! gh auth switch --user "$target" --hostname github.com; then
    echo "gh auth switch failed"
    return 1
  fi

  local email signingkey
  case $target in
    Adrian-LSY)
      email="adrian@rooftop.my"
      signingkey="~/.ssh/adrian_rooftop_ed25519.pub"
      ;;
    AdrianLSY)
      email="adrianlow1998@gmail.com"
      signingkey="~/.ssh/sites_ad_p3_ed25519.pub"
      ;;
    *)
      echo "Unknown account: $account"
      return 1
      ;;
  esac

  git config user.name "Adrian Low"
  git config user.email "$email"
  git config user.signingkey "$signingkey"
  git config gpg.format ssh
  git config commit.gpgsign true
  git config tag.gpgsign true
  git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

  echo "✓ Repo configured for $target ($email)"
}
