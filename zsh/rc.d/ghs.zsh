ghs() {
  if (( $# != 1 )); then
    echo "Usage: ghs <Adrian-LSY|AdrianLSY>"
    return 1
  fi
  local target=$1

  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not found"
    return 1
  fi

  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  chmod -f 600 ~/.ssh/adrian_rooftop_ed25519 ~/.ssh/sites_ad_p3_ed25519
  chmod -f 644 ~/.ssh/*.pub ~/.ssh/allowed_signers ~/.ssh/known_hosts ~/.ssh/config

  if ! gh auth switch --user "$target" --hostname github.com; then
    echo "gh auth switch failed"
    return 1
  fi

  local account
  account=$(gh api user -q '.login' 2>/dev/null)
  if [[ -z "$account" ]]; then
    echo "Could not determine active account"
    return 1
  fi

  case $account in
    Adrian-LSY)
      git config --global user.name "Adrian Low"
      git config --global user.email "adrian@rooftop.my"
      git config --global gpg.format ssh
      git config --global user.signingkey ~/.ssh/adrian_rooftop_ed25519.pub
      git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
      git config --global commit.gpgsign true
      git config --global tag.gpgsign true
      if [[ -f ~/.ssh/config ]]; then
        sed -i '/^\s*IdentityFile\s\+/c\    IdentityFile ~/.ssh/adrian_rooftop_ed25519' ~/.ssh/config
      fi
      echo "✓ Git & SSH config set for Adrian-LSY"
      ;;
    AdrianLSY)
      git config --global user.name "Adrian Low"
      git config --global user.email "adrianlow1998@gmail.com"
      git config --global gpg.format ssh
      git config --global user.signingkey ~/.ssh/sites_ad_p3_ed25519.pub
      git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
      git config --global commit.gpgsign true
      git config --global tag.gpgsign true
      if [[ -f ~/.ssh/config ]]; then
        sed -i '/^\s*IdentityFile\s\+/c\    IdentityFile ~/.ssh/sites_ad_p3_ed25519' ~/.ssh/config
      fi
      echo "✓ Git & SSH config set for AdrianLSY"
      ;;
    *)
      echo "Unknown account: $account"
      return 1
      ;;
  esac
}
