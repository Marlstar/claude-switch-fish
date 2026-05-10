function _cs_cmd_help
    _cs_print_header
    printf "  %sUSAGE%s\n" (set_color --bold) (set_color normal)
    printf "    claude-switch %s[command] [name]%s\n" (set_color brblack) (set_color normal)
    printf "    claude-switch %s<profile-name>%s          %s# quick launch%s\n\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "  %sCOMMANDS%s\n" (set_color --bold) (set_color normal)
    printf "    %s<name>%s                Launch Claude with that profile\n" (set_color cyan) (set_color normal)
    printf "    %screate%s %s[name]%s         Create a new profile\n" (set_color cyan) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %slist%s                  List all profiles and auth status\n" (set_color cyan) (set_color normal)
    printf "    %srename%s %s[old] [new]%s    Rename a profile\n" (set_color cyan) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sdelete%s %s[name]%s         Delete a profile\n" (set_color cyan) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %shelp%s                  Show this help message\n" (set_color cyan) (set_color normal)
    printf "    %sversion%s               Show version\n\n" (set_color cyan) (set_color normal)
    printf "  %sEXAMPLES%s\n" (set_color --bold) (set_color normal)
    printf "    %sclaude-switch work%s              %s# launch work profile%s\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sclaude-switch personal%s          %s# launch personal profile%s\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sclaude-switch create work%s       %s# create a new profile%s\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sclaude-switch rename work job%s   %s# rename work → job%s\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sclaude-switch list%s              %s# show all profiles%s\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "    %sclaude-switch%s                   %s# interactive menu%s\n\n" \
        (set_color brblack) (set_color normal) (set_color brblack) (set_color normal)
    printf "  %sHOW IT WORKS%s\n" (set_color --bold) (set_color normal)
    printf "    Each profile gets its own ~/.claude-<name>/ directory with\n"
    printf "    separate OAuth credentials and session data. Shared config\n"
    printf "    (skills, settings, CLAUDE.md) is symlinked from ~/.claude/.\n"
    echo ""
end
