function _cs_cmd_delete
    set -l name $argv[1]
    if test -z "$name"
        set name (_cs_pick_profile delete)
        if test $status -ne 0
            return 1
        end
    end

    if test "$name" = default
        _cs_print_error "Cannot delete the default profile."
        return 1
    end

    if not _cs_profile_exists $name
        _cs_print_error "Profile '$name' does not exist."
        return 1
    end

    set -l sname (_cs_sanitize_name $name)
    set -l dir (_cs_profile_dir $name)

    set -l cred_store (_cs_detect_credential_store)
    set -l cred_note
    if test -n "$cred_store"
        set cred_note "  Credential store: $cred_store"
    else
        set cred_note "  No credential store detected — tokens stored in profile dir only"
    end

    echo ""
    gum style \
        --border rounded \
        --border-foreground 196 \
        --padding "1 2" \
        --margin "0 2" \
        (gum style --bold --foreground 196 "Delete profile '$name'") \
        "" \
        "This will permanently remove:" \
        "  - Profile directory: ~/.claude-$sname/" \
        "  - Function file: $_cs_fish_functions_dir/claude-$sname.fish" \
        "  - Sessions, history, and cached data" \
        "" \
        $cred_note \
        (gum style --faint 'claude auth logout will run first to clear any keyring entries.')

    echo ""

    if not gum confirm "Delete profile '$name'?" --affirmative "Yes, delete" --negative "Cancel" --default=false
        echo ""
        _cs_print_info "Cancelled."
        echo ""
        return
    end

    echo ""

    _cs_print_info "Logging out of profile '$name'..."
    CLAUDE_CONFIG_DIR="$dir" claude auth logout 2>/dev/null
    or true

    rm -rf $dir
    _cs_print_success "Removed ~/.claude-$sname/"

    set -l func_file "$_cs_fish_functions_dir/claude-$sname.fish"
    if test -f $func_file
        rm $func_file
        _cs_print_success "Removed function file $func_file"
    end

    echo ""
    _cs_print_info "Open a new terminal to refresh functions."
    echo ""
end
