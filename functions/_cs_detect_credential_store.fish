function _cs_detect_credential_store
    set -l gnome_found 0
    command -v gnome-keyring-daemon >/dev/null 2>&1; and set gnome_found 1
    test -S "$XDG_RUNTIME_DIR/keyring/control"; and set gnome_found 1
    test -n "$GNOME_KEYRING_CONTROL"; and set gnome_found 1
    command -v secret-tool >/dev/null 2>&1; and set gnome_found 1
    if command -v gdbus >/dev/null 2>&1
        gdbus introspect --session --dest org.freedesktop.secrets --object-path / >/dev/null 2>&1
        and set gnome_found 1
    end
    if test $gnome_found -eq 1
        echo "GNOME Keyring"
        return
    end

    if command -v kwallet-query >/dev/null 2>&1
        echo "KWallet"
        return
    end

    if command -v pass >/dev/null 2>&1
        echo "pass"
        return
    end

    echo ""
end
