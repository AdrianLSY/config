function ghs
    # Require exactly one arg
    if test (count $argv) -ne 1
        echo "Usage: ghs <Adrian-LSY|AdrianLSY>"
        return 1
    end
    set -l target $argv[1]

    # Ensure gh exists
    if not type -q gh
        echo "Error: gh CLI not found"
        return 1
    end

    # SSH perms (quiet if files missing)
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    chmod -f 600 ~/.ssh/adrian_rooftop_ed25519 ~/.ssh/sites_ad_p3_ed25519
    chmod -f 644 ~/.ssh/*.pub ~/.ssh/allowed_signers ~/.ssh/known_hosts ~/.ssh/config

    # Switch account
    if not gh auth switch --user $target --hostname github.com
        echo "gh auth switch failed"
        return 1
    end

    # Determine active
    set -l account (gh api user -q '.login' 2>/dev/null)
    if test -z "$account"
        echo "Could not determine active account"
        return 1
    end

    switch $account
        case Adrian-LSY
            git config --global user.name "Adrian Low"
            git config --global user.email "adrian@rooftop.my"
            git config --global gpg.format ssh
            git config --global user.signingkey ~/.ssh/adrian_rooftop_ed25519.pub
            git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
            git config --global commit.gpgsign true
            git config --global tag.gpgsign true
            echo "✓ Git user/signing config set for Adrian-LSY"
        case AdrianLSY
            git config --global user.name "Adrian Low"
            git config --global user.email "adrianlow1998@gmail.com"
            git config --global gpg.format ssh
            git config --global user.signingkey ~/.ssh/sites_ad_p3_ed25519.pub
            git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
            git config --global commit.gpgsign true
            git config --global tag.gpgsign true
            echo "✓ Git user/signing config set for AdrianLSY"
        case '*'
            echo "Unknown account: $account"
            return 1
    end
end
