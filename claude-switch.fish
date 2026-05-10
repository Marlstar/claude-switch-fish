#!/usr/bin/env fish

# ─────────────────────────────────────────────────────────────────────────────
# claude-switch — Run multiple Claude Code accounts on one machine
# ─────────────────────────────────────────────────────────────────────────────

set VERSION "1.2.0"
set CLAUDE_HOME $HOME/.claude
set PROFILE_PREFIX $HOME/.claude-
set PROFILE_MARKER .profile-name
set FISH_FUNCTIONS_DIR $HOME/.config/fish/functions
set SHARED_ITEMS skills CLAUDE.md settings.json plugins

# ── Credential store detection ───────────────────────────────────────────────

function detect_credential_store
    # GNOME Keyring — check several indicators since secret-tool is a separate package
    set -l gnome_found 0
    # daemon binary present
    command -v gnome-keyring-daemon >/dev/null 2>&1; and set gnome_found 1
    # daemon is running (control socket exists)
    test -S "$XDG_RUNTIME_DIR/keyring/control"; and set gnome_found 1
    # env var set by the daemon for the current session
    test -n "$GNOME_KEYRING_CONTROL"; and set gnome_found 1
    # secret-tool CLI (libsecret-tools, optional companion)
    command -v secret-tool >/dev/null 2>&1; and set gnome_found 1
    # D-Bus secrets service (covers GNOME Keyring and KWallet 6 bridge)
    if command -v gdbus >/dev/null 2>&1
        gdbus introspect --session --dest org.freedesktop.secrets --object-path / >/dev/null 2>&1
        and set gnome_found 1
    end
    if test $gnome_found -eq 1
        echo "GNOME Keyring"
        return
    end

    # KWallet 5 (kwallet-query CLI) — KWallet 6 uses the DBus secrets bridge above
    if command -v kwallet-query >/dev/null 2>&1
        echo "KWallet"
        return
    end

    # pass — unix password store
    if command -v pass >/dev/null 2>&1
        echo "pass"
        return
    end

    echo ""
end

# ── Gum helpers ──────────────────────────────────────────────────────────────

function ensure_gum
    if command -v gum >/dev/null 2>&1
        return 0
    end
    echo ""
    printf "  %sgum%s is required for interactive menus.\n" (set_color yellow) (set_color normal)
    echo ""
    printf "  Install it:\n"
    printf "    %sgo install github.com/charmbracelet/gum@latest%s\n" (set_color cyan) (set_color normal)
    printf "    or via your package manager (nix-env -iA nixpkgs.gum, apt install gum, etc.)\n"
    exit 1
end

# ── Utility Functions ────────────────────────────────────────────────────────

function print_header
    echo ""
    gum style \
        --border double \
        --border-foreground 208 \
        --padding "1 3" \
        --margin "0 2" \
        --align center \
        (gum style --bold --foreground 208 'C L A U D E   S W I T C H') \
        "" \
        (gum style --faint "v$VERSION  ·  run multiple accounts side by side")
    echo ""
end

function print_success; printf "  %s✔%s  %s\n" (set_color green) (set_color normal) $argv[1]; end
function print_error;   printf "  %s✘%s  %s\n" (set_color red) (set_color normal) $argv[1]; end
function print_warn;    printf "  %s!%s  %s\n" (set_color yellow) (set_color normal) $argv[1]; end
function print_info;    printf "  %s▶%s  %s\n" (set_color blue) (set_color normal) $argv[1]; end
function print_dim;     printf "  %s   %s%s\n" (set_color brblack) $argv[1] (set_color normal); end

function sanitize_name
    # Replace spaces with hyphens for use in directory and function names
    string replace -a ' ' '-' -- $argv[1]
end

function validate_profile_name
    set -l name $argv[1]
    if test -z "$name"
        print_error "Profile name cannot be empty."
        return 1
    end
    if test "$name" = default
        print_error "'default' is reserved for the primary ~/.claude/ profile."
        return 1
    end
    if not string match -qr '^[a-zA-Z][a-zA-Z0-9 _-]*$' -- $name
        print_error "Invalid name. Use letters, numbers, spaces, hyphens, underscores. Must start with a letter."
        return 1
    end
    if string match -qr '  ' -- $name
        print_error "Profile name cannot contain consecutive spaces."
        return 1
    end
    if test (string length -- $name) -gt 32
        print_error "Profile name must be 32 characters or fewer."
        return 1
    end
    return 0
end

function profile_dir
    # Directory name uses the sanitized (space-free) form
    echo "$PROFILE_PREFIX"(sanitize_name $argv[1])
end

function profile_exists
    set -l dir (profile_dir $argv[1])
    test -d $dir; and test -f "$dir/$PROFILE_MARKER"
end

function get_all_profiles
    # Read the display name from the marker file (not the directory name),
    # so profiles with spaces in their names round-trip correctly.
    for dir in (find $HOME -maxdepth 1 -type d -name ".claude-*" 2>/dev/null | sort)
        set -l marker "$dir/$PROFILE_MARKER"
        test -f $marker; or continue
        cat $marker
    end
end

function check_auth_status
    set -l config_dir $argv[1]
    set -l output
    if test "$config_dir" = "$CLAUDE_HOME"
        set output (claude auth status 2>&1)
    else
        set output (env CLAUDE_CONFIG_DIR="$config_dir" claude auth status 2>&1)
    end
    set -l output_str (string join "\n" $output)
    set -l email (printf '%s\n' $output_str | grep -o '"email"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"email"[[:space:]]*:[[:space:]]*"//;s/"//')
    if test -n "$email"
        echo $email
    else if printf '%s\n' $output_str | grep -q '"loggedIn": true'
        echo "logged in"
    end
end

function pick_profile
    set -l action $argv[1]
    set -l profiles (get_all_profiles)
    if test (count $profiles) -eq 0
        print_warn "No profiles found. Create one first."
        return 1
    end
    set -l choice (printf '%s\n' $profiles | gum choose --header "Select a profile to $action:" --cursor.foreground 208 --header.foreground 252)
    if test -z "$choice"
        return 1
    end
    echo $choice
end

# ── Commands ─────────────────────────────────────────────────────────────────

function cmd_create
    set -l name $argv[1]
    if test -z "$name"
        set name (gum input --placeholder "Profile name (e.g. work, my work)" --header "Create a new profile" --cursor.foreground 208 --header.foreground 252)
    end

    if test -z "$name"
        print_info "Cancelled."
        exit 0
    end

    # Trim leading/trailing whitespace
    set name (string trim -- $name)

    if not validate_profile_name $name
        exit 1
    end

    set -l sname (sanitize_name $name)
    set -l dir (profile_dir $name)

    if test -d $dir; and test -f "$dir/$PROFILE_MARKER"
        set -l existing (cat "$dir/$PROFILE_MARKER")
        if test "$existing" = "$name"
            print_error "Profile '$name' already exists at $dir"
        else
            print_error "Profile '$name' conflicts with existing profile '$existing' (both map to $dir)"
        end
        exit 1
    end

    if test -d $dir; and not test -f "$dir/$PROFILE_MARKER"
        print_error "Directory $dir exists but is not a profile."
        print_dim "Inspect it manually or choose a different name."
        exit 1
    end

    printf "\n  %sCreating profile '%s%s%s%s'%s\n\n" \
        (set_color --bold) (set_color cyan) $name (set_color normal) (set_color --bold) (set_color normal)

    mkdir -p $dir
    # Marker stores the display name (may contain spaces)
    echo $name > "$dir/$PROFILE_MARKER"

    for item in $SHARED_ITEMS
        if test -e "$CLAUDE_HOME/$item"
            ln -sf "$CLAUDE_HOME/$item" "$dir/$item"
            printf "    %s→ %s%s\n" (set_color brblack) $item (set_color normal)
        else
            printf "    %s~ %s (not found, will link when created)%s\n" (set_color brblack) $item (set_color normal)
        end
    end

    echo ""
    print_success "Profile created at ~/.claude-$sname/"
    echo ""

    # Create fish function file — function name uses sanitized (space-free) form
    mkdir -p $FISH_FUNCTIONS_DIR
    set -l func_file "$FISH_FUNCTIONS_DIR/claude-$sname.fish"

    if test -f $func_file
        print_info "Function 'claude-$sname' already exists in $FISH_FUNCTIONS_DIR"
    else
        printf 'function claude-%s\n    env CLAUDE_CONFIG_DIR="%s" claude $argv\nend\n' $sname $dir > $func_file
        printf "  %s✔%s  Added function %sclaude-%s%s to %s\n" \
            (set_color green) (set_color normal) (set_color --bold) $sname (set_color normal) $FISH_FUNCTIONS_DIR
    end

    echo ""

    # Quote the name in the launch hint if it contains spaces
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

function cmd_list
    echo ""
    printf "  %sProfiles%s\n\n" (set_color --bold) (set_color normal)

    set -l default_label default
    if test -f "$CLAUDE_HOME/$PROFILE_MARKER"
        set default_label (cat "$CLAUDE_HOME/$PROFILE_MARKER")
    end

    set -l default_status (check_auth_status $CLAUDE_HOME)

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

    set -l profiles (get_all_profiles)
    for name in $profiles
        set -l sname (sanitize_name $name)
        set -l dir (profile_dir $name)
        set -l status (check_auth_status $dir)
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

    set -l cred_store (detect_credential_store)
    if test -n "$cred_store"
        printf "  %sCredential store: %s%s\n" (set_color brblack) $cred_store (set_color normal)
    else
        printf "  %sNo credential store detected (secret-tool / kwallet-query / pass)%s\n" \
            (set_color yellow) (set_color normal)
    end
    echo ""
end

function cmd_rename
    set -l old_name $argv[1]
    set -l new_name $argv[2]

    if test -z "$old_name"
        # Include "default" in the rename picker
        set -l profiles (get_all_profiles)
        set -l default_label default
        if test -f "$CLAUDE_HOME/$PROFILE_MARKER"
            set default_label (cat "$CLAUDE_HOME/$PROFILE_MARKER")
        end
        set old_name (printf '%s\n' $default_label $profiles | gum choose \
            --header "Select a profile to rename:" \
            --cursor.foreground 208 \
            --header.foreground 252)
        if test -z "$old_name"
            exit 0
        end
        # Map the display label back to "default" if user picked the default profile
        if test "$old_name" = "$default_label"; and test "$default_label" != default
            set old_name default
        end
    end

    if not profile_exists $old_name; and test "$old_name" != default
        print_error "Profile '$old_name' does not exist."
        exit 1
    end

    if test -z "$new_name"
        set new_name (gum input \
            --placeholder "New profile name" \
            --header "Rename '$old_name' to:" \
            --cursor.foreground 208 \
            --header.foreground 252)
    end

    if test -z "$new_name"
        print_info "Cancelled."
        exit 0
    end

    set new_name (string trim -- $new_name)

    if not validate_profile_name $new_name
        exit 1
    end

    if test "$new_name" = "$old_name"
        print_warn "New name is identical to the current name."
        exit 0
    end

    # Default profile: directory is fixed at ~/.claude/ — only update the display label
    if test "$old_name" = default
        echo $new_name > "$CLAUDE_HOME/$PROFILE_MARKER"
        echo ""
        print_success "Renamed default profile label '$old_name' → '$new_name'"
        print_dim "The directory stays at ~/.claude/ — 'default' still works as an alias."
        echo ""
        return
    end

    set -l old_sname (sanitize_name $old_name)
    set -l new_sname (sanitize_name $new_name)
    set -l old_dir (profile_dir $old_name)
    set -l new_dir (profile_dir $new_name)

    # Detect directory conflict only when the sanitized name actually changes
    if test "$old_sname" != "$new_sname"; and test -d $new_dir
        if test -f "$new_dir/$PROFILE_MARKER"
            set -l existing (cat "$new_dir/$PROFILE_MARKER")
            print_error "Name '$new_name' conflicts with existing profile '$existing'."
        else
            print_error "Directory $new_dir already exists and is not a profile."
        end
        exit 1
    end

    echo ""

    if test "$old_sname" != "$new_sname"
        # Directory path changes — move it and recreate the function file
        mv $old_dir $new_dir
        print_success "Moved ~/.claude-$old_sname/ → ~/.claude-$new_sname/"

        set -l old_func "$FISH_FUNCTIONS_DIR/claude-$old_sname.fish"
        if test -f $old_func
            rm $old_func
        end

        set -l new_func "$FISH_FUNCTIONS_DIR/claude-$new_sname.fish"
        printf 'function claude-%s\n    env CLAUDE_CONFIG_DIR="%s" claude $argv\nend\n' $new_sname $new_dir > $new_func
        print_success "Replaced function claude-$old_sname → claude-$new_sname"
    end

    # Update the display name stored in the marker (always)
    echo $new_name > "$new_dir/$PROFILE_MARKER"
    print_success "Renamed profile '$old_name' → '$new_name'"

    echo ""
    print_info "Open a new terminal to refresh functions."
    echo ""
end

function cmd_delete
    set -l name $argv[1]
    if test -z "$name"
        set name (pick_profile delete)
        if test $status -ne 0
            exit 1
        end
    end

    if test "$name" = default
        print_error "Cannot delete the default profile."
        exit 1
    end

    if not profile_exists $name
        print_error "Profile '$name' does not exist."
        exit 1
    end

    set -l sname (sanitize_name $name)
    set -l dir (profile_dir $name)

    set -l cred_store (detect_credential_store)
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
        "  - Function file: $FISH_FUNCTIONS_DIR/claude-$sname.fish" \
        "  - Sessions, history, and cached data" \
        "" \
        $cred_note \
        (gum style --faint 'claude auth logout will run first to clear any keyring entries.')

    echo ""

    if not gum confirm "Delete profile '$name'?" --affirmative "Yes, delete" --negative "Cancel" --default=false
        echo ""
        print_info "Cancelled."
        echo ""
        return
    end

    echo ""

    # Log out via Claude first so it can remove its own credential store entry
    print_info "Logging out of profile '$name'..."
    env CLAUDE_CONFIG_DIR="$dir" claude auth logout 2>/dev/null
    or true

    rm -rf $dir
    print_success "Removed ~/.claude-$sname/"

    set -l func_file "$FISH_FUNCTIONS_DIR/claude-$sname.fish"
    if test -f $func_file
        rm $func_file
        print_success "Removed function file $func_file"
    end

    echo ""
    print_info "Open a new terminal to refresh functions."
    echo ""
end

function cmd_launch
    set -l name $argv[1]
    if test -z "$name"
        set name (pick_profile launch)
        if test $status -ne 0
            exit 1
        end
    end

    if test "$name" = default
        exec claude
    end

    if not profile_exists $name
        print_error "Profile '$name' does not exist."
        print_dim "Run: claude-switch create $name"
        exit 1
    end

    set -l dir (profile_dir $name)
    exec env CLAUDE_CONFIG_DIR="$dir" claude
end

function cmd_interactive
    print_header

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
        case "Create a new profile"; cmd_create
        case "List all profiles";    cmd_list
        case "Launch a profile";     cmd_launch
        case "Rename a profile";     cmd_rename
        case "Delete a profile";     cmd_delete
        case "Exit" "";              exit 0
    end
end

function cmd_help
    print_header
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

# ── Main ─────────────────────────────────────────────────────────────────────

if not command -v claude >/dev/null 2>&1
    printf "  %s✘%s  Claude Code not found in PATH.\n" (set_color red) (set_color normal)
    printf "  %s   Install it first: https://docs.anthropic.com/en/docs/claude-code%s\n" \
        (set_color brblack) (set_color normal)
    exit 1
end

# Auto-check gum for interactive commands
switch $argv[1]
    case help -h --help version -v --version
        # no gum needed
    case '*'
        ensure_gum
end

switch $argv[1]
    case create
        cmd_create $argv[2..-1]
    case list ls
        cmd_list
    case rename mv
        cmd_rename $argv[2..-1]
    case delete rm remove
        cmd_delete $argv[2..-1]
    case launch run start
        cmd_launch $argv[2..-1]
    case help -h --help
        cmd_help
    case version -v --version
        echo "claude-switch v$VERSION"
    case ""
        cmd_interactive
    case '*'
        if profile_exists $argv[1]
            cmd_launch $argv[1]
        else
            printf "  %s✘%s  Unknown command or profile: %s\n" (set_color red) (set_color normal) $argv[1]
            echo ""
            cmd_help
            exit 1
        end
end
