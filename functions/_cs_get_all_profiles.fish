function _cs_get_all_profiles
    for dir in (find $HOME -maxdepth 1 -type d -name ".claude-*" 2>/dev/null | sort)
        set -l marker "$dir/$_cs_profile_marker"
        test -f $marker; or continue
        cat $marker
    end
end
