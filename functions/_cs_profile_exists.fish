function _cs_profile_exists
    set -l dir (_cs_profile_dir $argv[1])
    test -d $dir; and test -f "$dir/$_cs_profile_marker"
end
