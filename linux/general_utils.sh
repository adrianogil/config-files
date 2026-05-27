

function see-definition()
{
    # Show the definition of a target alias/function

    if [ -z "$1" ]
    then
        printf "Enter target function: "
        read -r target_function
    else
        target_function=$1
    fi

    if alias "${target_function}" >/dev/null 2>&1
    then
        echo "${target_function} is an alias"
        alias "${target_function}"
        return
    fi

    if type whence >/dev/null 2>&1
    then
        whence -f "${target_function}"
    else
        type "${target_function}"
    fi
}
alias sd="see-definition"
