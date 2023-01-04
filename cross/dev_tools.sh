

function swagger-generate-html()
{
    # Generate HTML documentation from Swagger YAML
    target_swagger_yaml_file=$1
    target_html_file=$2

    cat ${target_swagger_yaml_file} |  python3 ${CONFIG_FILES_DIR}/python/swagger/swagger.py > ${target_html_file}
}

# Search and execute bash scripts
function sha()
{
    target_shellscript=$(find . -name '*.sh' | default-fuzzy-finder)
    echo 'Running '${target_shellscript}
    ${target_shellscript}
}

function jabba-check-instslled-versions()
{
    jabba ls    
}


function jabba-install-java()
{
    jabba install $(jabba ls-remote | default-fuzzy-finder)
}

function jabba-uninstall-java()
{
    jabba uninstall $(jabba ls | default-fuzzy-finder)
}

function config-install-jabba()
{
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
}
