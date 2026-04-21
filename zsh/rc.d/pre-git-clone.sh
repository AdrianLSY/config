#!/bin/bash
if [[ $# -gt 0 ]]; then
  # Running directly with arguments
  TOOL_INPUT="$*"
else
  # Hook mode — JSON from stdin
  INPUT=$(cat)
  TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
fi

if ! echo "$TOOL_INPUT" | grep -q 'git clone'; then
  exit 0
fi

# Extract owner and repo from GitHub URL
# Handles git@github.com:owner/repo.git and https://github.com/owner/repo[.git]
OWNER=$(echo "$TOOL_INPUT" | sed -nE 's|.*github\.com[:/]([^/]+)/.*|\1|p' | head -1)
REPO=$(echo "$TOOL_INPUT" | sed -nE 's|.*github\.com[:/][^/]+/([^/ .]+).*|\1|p' | head -1)

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  exit 0
fi

ACCOUNT=""

# Direct username match
case "$OWNER" in
  Adrian-LSY) ACCOUNT="Adrian-LSY" ;;
  AdrianLSY)  ACCOUNT="AdrianLSY" ;;
esac

# For orgs/other owners, check which account has push access
if [[ -z "$ACCOUNT" ]]; then
  for try in Adrian-LSY AdrianLSY; do
    gh auth switch --user "$try" --hostname github.com 2>/dev/null
    PUSH=$(gh api "repos/$OWNER/$REPO" -q '.permissions.push // false' 2>/dev/null)
    if [[ "$PUSH" == "true" ]]; then
      ACCOUNT="$try"
      break
    fi
  done
fi

# Default to primary if neither has push access (e.g. public repo)
if [[ -z "$ACCOUNT" ]]; then
  ACCOUNT="AdrianLSY"
fi

# Switch account using ghs
source ~/.config/zsh/rc.d/ghs.zsh
ghs "$ACCOUNT" >/dev/null 2>&1

# Output instructions for the model
if [[ "$ACCOUNT" == "Adrian-LSY" ]]; then
  cat <<EOF
Auto-selected GitHub account: Adrian-LSY (adrian@rooftop.my) for $OWNER/$REPO.
Account switched. After the clone completes, cd into the repo and run:
  git config user.name "Adrian Low"
  git config user.email "adrian@rooftop.my"
  git config user.signingkey ~/.ssh/adrian_rooftop_ed25519.pub
  git config gpg.format ssh
  git config commit.gpgsign true
  git config tag.gpgsign true
  git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
EOF
else
  cat <<EOF
Auto-selected GitHub account: AdrianLSY (adrianlow1998@gmail.com) for $OWNER/$REPO.
Account switched. After the clone completes, cd into the repo and run:
  git config user.name "Adrian Low"
  git config user.email "adrianlow1998@gmail.com"
  git config user.signingkey ~/.ssh/sites_ad_p3_ed25519.pub
  git config gpg.format ssh
  git config commit.gpgsign true
  git config tag.gpgsign true
  git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
EOF
fi
