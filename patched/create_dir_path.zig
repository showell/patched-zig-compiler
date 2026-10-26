const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    std.Io.Dir.cwd().createDirPath(init.io, args[1]) catch |err| {
        std.debug.print("error.{t}\n", .{err});
        return;
    };
    std.debug.print("ok\n", .{});
}
