function ghs
    if test (count $argv) -ne 1
        echo "Usage: ghs <Adrian-LSY|AdrianLSY>"
        return 1
    end

    if not type -q gh
        echo "Error: gh CLI not found"
        return 1
    end

    if not git rev-parse --is-inside-work-tree &>/dev/null
        echo "Error: not inside a git repository"
        return 1
    end

    set -l target $argv[1]

    if not gh auth switch --user $target --hostname github.com
        echo "gh auth switch failed"
        return 1
    end

    set -l email
    set -l signingkey
    switch $target
        case Adrian-LSY
            set email "adrian@rooftop.my"
            set signingkey "~/.ssh/adrian_rooftop_ed25519.pub"
        case AdrianLSY
            set email "adrianlow1998@gmail.com"
            set signingkey "~/.ssh/sites_ad_p3_ed25519.pub"
        case '*'
            echo "Unknown account: $target"
            return 1
    end

    git config user.name "Adrian Low"
    git config user.email "$email"
    git config user.signingkey "$signingkey"
    git config gpg.format ssh
    git config commit.gpgsign true
    git config tag.gpgsign true
    git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

    echo "✓ Repo configured for $target ($email)"
end
