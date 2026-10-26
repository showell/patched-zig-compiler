const std = @import("std");

// A request that does not fit the arena's node grows it by the request once
// (patch "std.heap.ArenaAllocator: grow by the request once, not twice").
// Unpatched, the node grows to hold 200,100 bytes here.
test "a request that does not fit grows the node by the request once" {
    var buf: [1 << 20]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    var arena: std.heap.ArenaAllocator = .init(fba.allocator());
    defer arena.deinit();
    const a = arena.allocator();

    _ = try a.alloc(u8, 100);
    _ = try a.alloc(u8, 100_000);
    try std.testing.expect(arena.queryCapacity() < 100_100 + 200);
}
