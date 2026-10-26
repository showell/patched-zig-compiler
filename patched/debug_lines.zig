const std = @import("std");

pub fn pick(r: std.Random, comptime weights: anytype) std.meta.FieldEnum(@TypeOf(weights)) {
    _ = r;
    return @enumFromInt(0);
}

test "pick" {
    var prng: std.Random.DefaultPrng = .init(1);
    _ = pick(prng.random(), .{ .a = 3, .b = 1 });
}
