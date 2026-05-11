function _cs_cmd_create
    set -l name $argv[1]
    if test -z "$name"
        set name (gum input --placeholder "Profile name (e.g. work, my work)" --header "Create a new profile" --cursor.foreground 208 --header.foreground 252)
    end

    if test -z "$name"
        _cs_print_info "Cancelled."
        return 0
    end

    set name (string trim -- $name)

    if not _cs_validate_profile_name $name
        return 1
    end

    set -l sname (_cs_sanitize_name $name)
    set -l dir (_cs_profile_dir $name)

    if test -d $dir; and test -f "$dir/$_cs_profile_marker"
        set -l existing (cat "$dir/$_cs_profile_marker")
        if test "$existing" = "$name"
            _cs_print_error "Profile '$name' already exists at $dir"
        else
            _cs_print_error "Profile '$name' conflicts with existing profile '$existing' (both map to $dir)"
        end
        return 1
    end

    if test -d $dir; and not test -f "$dir/$_cs_profile_marker"
        _cs_print_error "Directory $dir exists but is not a profile."
        _cs_print_dim "Inspect it manually or choose a different name."
        return 1
    end

    printf "\n  %sCreating profile '%s%s%s%s'%s\n\n" \
        (set_color --bold) (set_color cyan) $name (set_color normal) (set_color --bold) (set_color normal)

    mkdir -p $dir
    echo $name > "$dir/$_cs_profile_marker"

    for item in $_cs_shared_items
        if test -e "$_cs_claude_home/$item"
            ln -sf "$_cs_claude_home/$item" "$dir/$item"
            printf "    %s→ %s%s\n" (set_color brblack) $item (set_color normal)
        else
            printf "    %s~ %s (not found, will link when created)%s\n" (set_color brblack) $item (set_color normal)
        end
    end

    echo ""
    _cs_print_success "Profile created at ~/.claude-$sname/"
    echo ""

    mkdir -p $_cs_fish_functions_dir
    set -l func_file "$_cs_fish_functions_dir/claude-$sname.fish"

    if test -f $func_file
        _cs_print_info "Function 'claude-$sname' already exists in $_cs_fish_functions_dir"
    else
        printf 'function claude-%s\n    CLAUDE_CONFIG_DIR="%s" claude $argv\nend\n' $sname $dir > $func_file
        printf "  %s✔%s  Added function %sclaude-%s%s to %s\n" \
            (set_color green) (set_color normal) (set_color --bold) $sname (set_color normal) $_cs_fish_functions_dir
    end

    echo ""

    set -l launch_name $name
    if string match -q '* *' -- $name
        set launch_name "\"$name\""
    end

    gum style \
        --border rounded \
        --border-foreground 240 \
        --padding "1 2" \
        --margin "0 2" \
        (gum style --bold 'Quick start') \
        "" \
        "  source $func_file" \
        "  "(gum style --foreground 99 "claude-switch $launch_name") \
        "  "(gum style --foreground 99 "claude-$sname") \
        "" \
        (gum style --faint 'Claude will prompt you to log in on first launch.')

    echo ""
end
