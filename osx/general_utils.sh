

# config-tools see-definition: Show the definition of a target function
function see-definition()
{
    # Show the definition of a target function

    if [ -z "$1" ]
    then
        # zsh
        echo "Enter target function: " 
        read target_function
    else
        target_function=$1
    fi

    whence -f ${target_function}
}
alias sd="see-definition"