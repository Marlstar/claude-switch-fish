function _cs_sanitize_name
    string replace -a ' ' '-' -- $argv[1]
end
