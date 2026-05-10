function _cs_cmd_interactive
    _cs_print_header

    set -l choice (gum choose \
        "Create a new profile" \
        "List all profiles" \
        "Launch a profile" \
        "Rename a profile" \
        "Delete a profile" \
        "Exit" \
        --header "What would you like to do?" \
        --cursor.foreground 208 \
        --header.foreground 252 \
        --cursor "▶ " \
        --selected.foreground 208)

    switch $choice
        case "Create a new profile"; _cs_cmd_create
        case "List all profiles";    _cs_cmd_list
        case "Launch a profile";     _cs_cmd_launch
        case "Rename a profile";     _cs_cmd_rename
        case "Delete a profile";     _cs_cmd_delete
        case "Exit" "";              return 0
    end
end
