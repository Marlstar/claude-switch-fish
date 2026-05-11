function _cs_cmd_rename
    set -l old_name $argv[1]
    set -l new_name $argv[2]

    if test -z "$old_name"
        set -l profiles (_cs_get_all_profiles)
        set -l default_label default
        if test -f "$_cs_claude_home/$_cs_profile_marker"
            set default_label (cat "$_cs_claude_home/$_cs_profile_marker")
        end
        set old_name (printf '%s\n' $default_label $profiles | gum choose \
            --header "Select a profile to rename:" \
            --cursor.foreground 208 \
            --header.foreground 252)
        if test -z "$old_name"
            return 0
        end
        if test "$old_name" = "$default_label"; and test "$default_label" != default
            set old_name default
        end
    end

    if not _cs_profile_exists $old_name; and test "$old_name" != default
        _cs_print_error "Profile '$old_name' does not exist."
        return 1
    end

    if test -z "$new_name"
        set new_name (gum input \
            --placeholder "New profile name" \
            --header "Rename '$old_name' to:" \
            --cursor.foreground 208 \
            --header.foreground 252)
    end

    if test -z "$new_name"
        _cs_print_info "Cancelled."
        return 0
    end

    set new_name (string trim -- $new_name)

    if not _cs_validate_profile_name $new_name
        return 1
    end

    if test "$new_name" = "$old_name"
        _cs_print_warn "New name is identical to the current name."
        return 0
    end

    if test "$old_name" = default
        echo $new_name > "$_cs_claude_home/$_cs_profile_marker"
        echo ""
        _cs_print_success "Renamed default profile label '$old_name' → '$new_name'"
        _cs_print_dim "The directory stays at ~/.claude/ — 'default' still works as an alias."
        echo ""
        return
    end

    set -l old_sname (_cs_sanitize_name $old_name)
    set -l new_sname (_cs_sanitize_name $new_name)
    set -l old_dir (_cs_profile_dir $old_name)
    set -l new_dir (_cs_profile_dir $new_name)

    if test "$old_sname" != "$new_sname"; and test -d $new_dir
        if test -f "$new_dir/$_cs_profile_marker"
            set -l existing (cat "$new_dir/$_cs_profile_marker")
            _cs_print_error "Name '$new_name' conflicts with existing profile '$existing'."
        else
            _cs_print_error "Directory $new_dir already exists and is not a profile."
        end
        return 1
    end

    echo ""

    if test "$old_sname" != "$new_sname"
        mv $old_dir $new_dir
        _cs_print_success "Moved ~/.claude-$old_sname/ → ~/.claude-$new_sname/"

        set -l old_func "$_cs_fish_functions_dir/claude-$old_sname.fish"
        if test -f $old_func
            rm $old_func
        end

        set -l new_func "$_cs_fish_functions_dir/claude-$new_sname.fish"
        printf 'function claude-%s\n    CLAUDE_CONFIG_DIR="%s" claude $argv\nend\n' $new_sname $new_dir > $new_func
        _cs_print_success "Replaced function claude-$old_sname → claude-$new_sname"
    end

    echo $new_name > "$new_dir/$_cs_profile_marker"
    _cs_print_success "Renamed profile '$old_name' → '$new_name'"

    echo ""
    _cs_print_info "Open a new terminal to refresh functions."
    echo ""
end
