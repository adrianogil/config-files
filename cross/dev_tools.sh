

function swagger-generate-html()
{
    # Generate HTML documentation from Swagger YAML
    target_swagger_yaml_file=$1
    target_html_file=$2

    cat ${target_swagger_yaml_file} |  python3 ${CONFIG_FILES_DIR}/python/swagger/swagger.py > ${target_html_file}
}
