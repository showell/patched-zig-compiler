//! Roc's allocations on a std.heap.ArenaAllocator, as a server host keeps
//! them (one arena per request), with every request the arena makes of its
//! own allocator printed.
const std = @import("std");

const RocList = extern struct { bytes: ?[*]u8, length: usize, capacity_or_alloc_ptr: usize };

extern fn roc_make(n: u64) callconv(.c) RocList;

/// The arena's own allocator: a bump allocator, which can grow its last
/// block in place, logging what the arena asks of it.
const Logging = struct {
    child: std.mem.Allocator,

    fn allocator(self: *Logging) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &.{ .alloc = alloc, .resize = resize, .remap = remap, .free = free } };
    }
    fn alloc(ctx: *anyopaque, n: usize, a: std.mem.Alignment, ra: usize) ?[*]u8 {
        const self: *Logging = @ptrCast(@alignCast(ctx));
        std.debug.print("  arena asks: alloc  {d}\n", .{n});
        return self.child.rawAlloc(n, a, ra);
    }
    fn resize(ctx: *anyopaque, m: []u8, a: std.mem.Alignment, n: usize, ra: usize) bool {
        const self: *Logging = @ptrCast(@alignCast(ctx));
        std.debug.print("  arena asks: resize {d} -> {d}\n", .{ m.len, n });
        return self.child.rawResize(m, a, n, ra);
    }
    fn remap(ctx: *anyopaque, m: []u8, a: std.mem.Alignment, n: usize, ra: usize) ?[*]u8 {
        const self: *Logging = @ptrCast(@alignCast(ctx));
        return self.child.rawRemap(m, a, n, ra);
    }
    fn free(ctx: *anyopaque, m: []u8, a: std.mem.Alignment, ra: usize) void {
        const self: *Logging = @ptrCast(@alignCast(ctx));
        self.child.rawFree(m, a, ra);
    }
};

var backing: [8 << 20]u8 = undefined;
var fba: std.heap.FixedBufferAllocator = .init(&backing);
var logging: Logging = .{ .child = undefined };
var arena: std.heap.ArenaAllocator = undefined;
var asked: usize = 0;

/// Each block carries its length in front, for roc_realloc's copy.
const header = 16;

export fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    std.debug.print("roc_alloc {d}\n", .{len});
    asked += len;
    _ = alignment;
    const block = arena.allocator().alignedAlloc(u8, .@"16", header + len) catch @panic("out of memory");
    @as(*usize, @ptrCast(block.ptr)).* = len;
    return block.ptr + header;
}
export fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    const old: [*]u8 = @ptrCast(ptr);
    const old_len = @as(*usize, @ptrCast(@alignCast(old - header))).*;
    const new: [*]u8 = @ptrCast(roc_alloc(len, alignment));
    @memcpy(new[0..@min(len, old_len)], old[0..@min(len, old_len)]);
    return new;
}
export fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = ptr;
    _ = alignment;
}
export fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.print("roc crashed: {s}\n", .{bytes[0..len]});
    std.process.exit(2);
}

pub fn main() void {
    logging.child = fba.allocator();
    arena = .init(logging.allocator());
    const n = 1_000_000;
    std.debug.print("make({d}) on Zig {s}:\n", .{ n, @import("builtin").zig_version_string });
    const r = roc_make(n);
    std.debug.print("list of {d} bytes; Roc asked for {d}; the arena holds {d}\n", .{ r.length, asked, arena.queryCapacity() });
}
