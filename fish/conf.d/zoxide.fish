if status is-interactive
    zoxide init fish | source
    function cd
        # Replaces cd with zoxide if argument is not a directory
        if test (count $argv) -eq 0
            # No arguments - go to home directory
            builtin cd
        else if test -d $argv[1]
            # If it's a valid directory path, use regular cd
            builtin cd $argv
        else
            # Otherwise, try zoxide
            z $argv
        end
    end
end
