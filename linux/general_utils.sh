

function see-definition()
{
    # Show the definition of a target function

    if [ -z "$1" ]
    then
        # zsh
        read -p "Enter target function: " target_function
    else
        target_function=$1
    fi

    type ${target_function}
}
alias sd="see-definition"
