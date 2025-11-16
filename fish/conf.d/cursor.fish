function cur --description 'Runs cursor'
    cursor $argv
end

function curr --description 'Runs cursor and close the terminal'
    cursor $argv
    exit
end
