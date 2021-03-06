const std = @import("std");

const util = @import("util.zig");

const Server = @import("Server.zig");

pub fn main() anyerror!void {
    var server: Server = undefined;
    try server.init();
    defer server.deinit();

    try server.start();

    if (std.os.argv.len > 1) {
        const child_args = [_][]const u8{ "/bin/sh", "-c", std.mem.spanZ(std.os.argv[1]) };
        const child = try std.ChildProcess.init(&child_args, util.allocator);
        defer child.deinit();
        try std.ChildProcess.spawn(child);
    }

    server.run();
}
