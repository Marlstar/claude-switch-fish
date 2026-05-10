function _cs_cmd_list
    echo ""
    printf "  %sProfiles%s\n\n" (set_color --bold) (set_color normal)

    set -l default_label default
    if test -f "$_cs_claude_home/$_cs_profile_marker"
        set default_label (cat "$_cs_claude_home/$_cs_profile_marker")
    end

    set -l default_status (_cs_check_auth_status $_cs_claude_home)

    if test -n "$default_status"
        printf "  ◉  %s%-16s%s %s%-24s%s %s✔ %s%s\n" \
            (set_color --bold) $default_label (set_color normal) \
            (set_color brblack) "~/.claude/" (set_color normal) \
            (set_color green) $default_status (set_color normal)
    else
        printf "  ◉  %s%-16s%s %s%-24s%s %s✘ not logged in%s\n" \
            (set_color --bold) $default_label (set_color normal) \
            (set_color brblack) "~/.claude/" (set_color normal) \
            (set_color red) (set_color normal)
    end

    set -l profiles (_cs_get_all_profiles)
    for name in $profiles
        set -l sname (_cs_sanitize_name $name)
        set -l dir (_cs_profile_dir $name)
        set -l status (_cs_check_auth_status $dir)
        if test -n "$status"
            printf "  ◉  %s%-16s%s %s%-24s%s %s✔ %s%s\n" \
                (set_color --bold) $name (set_color normal) \
                (set_color brblack) "~/.claude-$sname/" (set_color normal) \
                (set_color green) $status (set_color normal)
        else
            printf "  ◉  %s%-16s%s %s%-24s%s %s✘ not logged in%s\n" \
                (set_color --bold) $name (set_color normal) \
                (set_color brblack) "~/.claude-$sname/" (set_color normal) \
                (set_color red) (set_color normal)
        end
    end

    echo ""
    set -l count (math (count $profiles) + 1)
    printf "  %s%d profile(s) total%s\n" (set_color brblack) $count (set_color normal)

    set -l cred_store (_cs_detect_credential_store)
    if test -n "$cred_store"
        printf "  %sCredential store: %s%s\n" (set_color brblack) $cred_store (set_color normal)
    else
        printf "  %sNo credential store detected (secret-tool / kwallet-query / pass)%s\n" \
            (set_color yellow) (set_color normal)
    end
    echo ""
end
