function _cs_cmd_launch
    set -l name $argv[1]
    if test -z "$name"
        set name (_cs_pick_profile launch)
        if test $status -ne 0
            return 1
        end
    end

    if test "$name" = default
        claude
        return
    end

    if not _cs_profile_exists $name
        _cs_print_error "Profile '$name' does not exist."
        _cs_print_dim "Run: claude-switch create $name"
        return 1
    end

    set -l dir (_cs_profile_dir $name)
    CLAUDE_CONFIG_DIR="$dir" claude
end
