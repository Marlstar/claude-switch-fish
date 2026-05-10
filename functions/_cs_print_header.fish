function _cs_print_header
    echo ""
    gum style \
        --border double \
        --border-foreground 208 \
        --padding "1 3" \
        --margin "0 2" \
        --align center \
        (gum style --bold --foreground 208 'C L A U D E   S W I T C H') \
        "" \
        (gum style --faint "v$_cs_version  ·  run multiple accounts side by side")
    echo ""
end
