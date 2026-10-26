# The arena patch, seen from Roc

**What it shows:** a Roc program whose host keeps Roc's allocations on a
`std.heap.ArenaAllocator` (as a server host does, one arena per request)
pays for the arena bug with Roc's own allocations; no hosted function is
involved. Found while explaining why the Roc chat's `/raw` took 6x its
transcript (metal-vmm FEEDBACK, 2026-10-26); this was 2 of the 6.

`app.roc`'s `make(n)` makes a 100-byte list and an `n`-byte one and
concatenates them. `host.zig` backs `roc_alloc` with an arena over a bump
allocator that logs what the arena asks of it.

**Run it** from this folder (the pinned Roc, `nightly-2026-10-09-258ab27`):

    roc build app.roc --target=x64musl --output=app.a
    zig build-exe host.zig app.a -target x86_64-linux-musl -O ReleaseSafe -femit-bin=host
    ./host

**Stock 0.17.0 printed:**

    make(1000000) on Zig 0.17.0:
    roc_alloc 1000008
      arena asks: alloc  1500120
    roc_alloc 148
    roc_alloc 2000008
      arena asks: resize 1500120 -> 5000296
    list of 1000100 bytes; Roc asked for 3000164; the arena holds 5000272

**With the patch** (`0.17.0+patched.1`), the same but:

      arena asks: resize 1500120 -> 3500152
    list of 1000100 bytes; Roc asked for 3000164; the arena holds 3500128

The concat's 2,000,008 doesn't fit the node; stock grows the node by it
twice (5.0 MB), patched once (3.5 MB). That `concat` asks for 2 MB to
hold 1,000,100 bytes is Roc's own doubling, not this bug.
