const std = @import("std");

const Client = @import("Client.zig");
const Server = @import("Server.zig");

pub fn main() anyerror!void {
    var server: Server = undefined;
    try server.init();
    defer server.deinit();

    var client: Client = undefined;
    try client.init(&server);

    try server.start();

    // spawn child

    server.run();
}
