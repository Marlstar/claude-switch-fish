function _cs_validate_profile_name
    set -l name $argv[1]
    if test -z "$name"
        _cs_print_error "Profile name cannot be empty."
        return 1
    end
    if test "$name" = default
        _cs_print_error "'default' is reserved for the primary ~/.claude/ profile."
        return 1
    end
    if not string match -qr '^[a-zA-Z][a-zA-Z0-9 _-]*$' -- $name
        _cs_print_error "Invalid name. Use letters, numbers, spaces, hyphens, underscores. Must start with a letter."
        return 1
    end
    if string match -qr '  ' -- $name
        _cs_print_error "Profile name cannot contain consecutive spaces."
        return 1
    end
    if test (string length -- $name) -gt 32
        _cs_print_error "Profile name must be 32 characters or fewer."
        return 1
    end
    return 0
end
