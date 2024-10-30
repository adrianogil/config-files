
# config-tools cdback: Fuzzy-search and enter a directory from cd stack
function cdback() {
    last_path=$(dirs -lv | default-fuzzy-finder | awk '{$1=""; print substr($0,2)}')
    cd "${last_path}"
}

