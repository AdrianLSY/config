set -l __zox "$HOME/.local/bin/zoxide"
if test -x $__zox
    $__zox init fish | source

    function cd
        if test (count $argv) -eq 0
            builtin cd
        else if test -d $argv[1]
            builtin cd $argv
        else if functions -q z
            z $argv
        else
            builtin cd $argv
        end
    end
end
