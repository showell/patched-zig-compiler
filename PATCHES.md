# Patched Zig 0.17.0

Zig 0.17.0 as released, plus fixes we need and have reported upstream. The
compiler our projects build with; each release is a static x86_64-linux
compiler laid out as ziglang.org's tarballs.

- **The history is the record.** The first commit is the 0.17.0 source
  tarball, unchanged (tag `upstream-0.17.0`); each patch is one commit
  after it, its message saying the bug, the fix, and how it was tested.
  `git diff upstream-0.17.0` is everything we changed.
- **A release** is a tag `patched.N`; it builds version `0.17.0+patched.N`
  (`zig version` says so; the `+patched.N` is semver build metadata, so a
  package's `minimum_zig_version = "0.17.0"` still holds).
  `.github/workflows/release.yml` builds it the way Zig's own release CI
  builds 0.17.0, against Zig's prebuilt LLVM 22 bundle, runs the patches'
  checks and the behavior tests, and publishes
  `zig-x86_64-linux-0.17.0+patched.N.tar.xz` with its `.sha256`. `zig-version`
  names the newest release.

## The patches

| Patch | What it fixes | Upstream report |
|---|---|---|
| `Zir: decode a function's payload in one place (getFnPayload)` | A generic function's debug line rows (prologue, epilogue) past the end of its file, when its return type names a parameter: `Sema.zirFunc` read `SrcLocs` from the body. Six hand-walks of a function's ZIR payload become one decoder. | draft: essay-repl-server `notes/zig-issue-generic-debug-lines.md` |
| `std.heap.ArenaAllocator: grow by the request once, not twice` | A request that doesn't fit the arena's node grew it by twice the request (the fast path's failed reservation counted again). | draft: essay-repl-server `notes/zig-issue-arena-overshoot.md` |

`patched/check.sh <zig>` checks both: each fails on unpatched 0.17.0.

## Using it

**Install** (the box and CC alike), from a project's root:

    curl -fsSL https://raw.githubusercontent.com/showell/patched-zig-compiler/main/tools/get_zig.sh | sh

It installs the version the project's `zig-version` names into
`~/zig-<version>/` and links `~/.local/bin/zig` to it (`~/.local/bin` first
on the PATH). With no `zig-version` there, the newest release.

**Pin a project**: a `zig-version` file at its root holding the version
(`0.17.0+patched.1`), and in its `build.zig`:

```zig
// The pinned compiler: zig-version, from github.com/showell/patched-zig-compiler
// (its tools/get_zig.sh installs it).
comptime {
    const pinned = std.mem.trim(u8, @embedFile("zig-version"), " \n");
    if (!std.mem.eql(u8, @import("builtin").zig_version_string, pinned))
        @compileError("this build needs Zig " ++ pinned ++ " (zig-version), not " ++
            @import("builtin").zig_version_string ++ ": patched-zig-compiler's tools/get_zig.sh installs it");
}
```

Any other compiler, stock 0.17.0 included, then stops at the build's first
line with that message.

**A new patch**: one commit on `main` (its message as the others'), a check
in `patched/check.sh`, then tag `patched.N+1` and push the tag; when the
release is up, move `zig-version` and the projects' pins.

**A new Zig**: when upstream ships the fixes (or a new release we move to),
start from that release's tarball the same way and carry over only the
patches it still needs.
