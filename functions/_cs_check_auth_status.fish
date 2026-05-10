function _cs_check_auth_status
    set -l config_dir $argv[1]
    set -l output
    if test "$config_dir" = "$_cs_claude_home"
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
