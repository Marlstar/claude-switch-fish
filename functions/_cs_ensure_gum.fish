function _cs_ensure_gum
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
