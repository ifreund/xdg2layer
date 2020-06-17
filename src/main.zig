const std = @import("std");

pub fn main() anyerror!void {
    var server = undefined;
    try server.init();
    defer server.deinit();

    try client.init(&server);
    try server.start();

    // spawn child
    server.run();
}
