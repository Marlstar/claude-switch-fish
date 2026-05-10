function claude-switch
    if not command -v claude >/dev/null 2>&1
        printf "  %s✘%s  Claude Code not found in PATH.\n" (set_color red) (set_color normal)
        printf "  %s   Install it first: https://docs.anthropic.com/en/docs/claude-code%s\n" \
            (set_color brblack) (set_color normal)
        return 1
    end

    switch $argv[1]
        case help -h --help version -v --version
            # no gum needed
        case '*'
            _cs_ensure_gum
    end

    switch $argv[1]
        case create
            _cs_cmd_create $argv[2..-1]
        case list ls
            _cs_cmd_list
        case rename mv
            _cs_cmd_rename $argv[2..-1]
        case delete rm remove
            _cs_cmd_delete $argv[2..-1]
        case launch run start
            _cs_cmd_launch $argv[2..-1]
        case help -h --help
            _cs_cmd_help
        case version -v --version
            echo "claude-switch v$_cs_version"
        case ""
            _cs_cmd_interactive
        case default
            _cs_cmd_launch default
        case '*'
            if _cs_profile_exists $argv[1]
                _cs_cmd_launch $argv[1]
            else
                printf "  %s✘%s  Unknown command or profile: %s\n" (set_color red) (set_color normal) $argv[1]
                echo ""
                _cs_cmd_help
                return 1
            end
    end
end
