if type -q zoxide
    zoxide init fish | source
    function cd
        if test (count $argv) -eq 0
            builtin cd
        else if test -d $argv[1]
            builtin cd $argv
        else
            z $argv
        end
    end
end
