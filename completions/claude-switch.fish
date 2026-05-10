# Disable file completions for claude-switch
complete -c claude-switch -f

# Subcommands
complete -c claude-switch -n __fish_use_subcommand -a create  -d 'Create a new profile'
complete -c claude-switch -n __fish_use_subcommand -a list    -d 'List all profiles and auth status'
complete -c claude-switch -n __fish_use_subcommand -a rename  -d 'Rename a profile'
complete -c claude-switch -n __fish_use_subcommand -a delete  -d 'Delete a profile'
complete -c claude-switch -n __fish_use_subcommand -a launch  -d 'Launch a profile'
complete -c claude-switch -n __fish_use_subcommand -a help    -d 'Show help'
complete -c claude-switch -n __fish_use_subcommand -a version -d 'Show version'

# Profile name completions for subcommands that take a profile argument
function __cs_complete_profiles
    _cs_get_all_profiles 2>/dev/null
end

complete -c claude-switch -n '__fish_seen_subcommand_from launch run start rename delete rm remove' \
    -a '(__cs_complete_profiles)'

# Profile quick-launch: complete profile names when no subcommand given
complete -c claude-switch -n __fish_use_subcommand -a '(__cs_complete_profiles)'
