function _cs_pick_profile
    set -l action $argv[1]
    set -l profiles (_cs_get_all_profiles)
    if test (count $profiles) -eq 0
        _cs_print_warn "No profiles found. Create one first."
        return 1
    end
    set -l choice (printf '%s\n' $profiles | gum choose --header "Select a profile to $action:" --cursor.foreground 208 --header.foreground 252)
    if test -z "$choice"
        return 1
    end
    echo $choice
end
