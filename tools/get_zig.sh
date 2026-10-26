#!/bin/sh
# **THE PINNED ZIG, INSTALLED**: the version a project's `zig-version` names
# (run from the project's root), or this repository's own `zig-version` (the
# newest release) when there is none, from this repository's release of
# that version, into ~/zig-<version>/, and ~/.local/bin/zig linked to it
# (put ~/.local/bin first on the PATH). Already there and answering the pin,
# it is only linked again.
#
#     cd <project> && <this checkout>/tools/get_zig.sh
#     cd <project> && curl -fsSL https://raw.githubusercontent.com/showell/patched-zig-compiler/main/tools/get_zig.sh | sh
#
# A version is `0.17.0+patched.N`, released under the tag `patched.N`.
set -eu

if [ -f zig-version ]; then
    pin=$(tr -d '[:space:]' < zig-version)
    from="$(pwd)/zig-version"
else
    pin=$(curl -fsSL https://raw.githubusercontent.com/showell/patched-zig-compiler/main/zig-version | tr -d '[:space:]')
    from="patched-zig-compiler's zig-version"
fi
case "$pin" in
    *+patched.[0-9]*) ;;
    *) echo "get_zig: $from names $pin, not a 0.17.0+patched.N version" >&2; exit 1 ;;
esac

case "$(uname -s) $(uname -m)" in
    "Linux x86_64") ;;
    *) echo "get_zig: patched-zig-compiler releases x86_64-linux only, not $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

dest="$HOME/zig-$pin"
says() { "$dest/zig" version 2>/dev/null; }
if [ ! -x "$dest/zig" ] || [ "$(says)" != "$pin" ]; then
    tag=${pin#*+}
    name="zig-x86_64-linux-$pin"
    base="https://github.com/showell/patched-zig-compiler/releases/download/$tag"
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    echo "get_zig: $base/$name.tar.xz"
    curl -fL --retry 3 -o "$work/$name.tar.xz" "$base/$(echo "$name" | sed 's/+/%2B/').tar.xz"
    curl -fsSL --retry 3 -o "$work/$name.tar.xz.sha256" "$base/$(echo "$name" | sed 's/+/%2B/').tar.xz.sha256"
    (cd "$work" && sha256sum -c "$name.tar.xz.sha256" >/dev/null) || { echo "get_zig: $name.tar.xz does not match its .sha256" >&2; exit 1; }
    tar -xJf "$work/$name.tar.xz" -C "$work"
    rm -rf "$dest"
    mv "$work/$name" "$dest"
    [ "$(says)" = "$pin" ] || { echo "get_zig: $dest/zig says $("$dest/zig" version), not $pin" >&2; exit 1; }
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$dest/zig" "$HOME/.local/bin/zig"
echo "get_zig: ~/.local/bin/zig -> $dest/zig ($pin)"
