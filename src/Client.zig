const Self = @This();

const std = @import("std");
const c = @import("c.zig");

const Server = @import("Server.zig");

const wl_registry_listener = c.wl_registry_listener{
    .global = handleGlobal,
    .global_remove = handleGlobalRemove,
};

server: *Server,
wl_display: *c.wl_display,

pub fn init(self: *Self, server: *Server) !void {
    self.wl_display = c.wl_display_connect(null) orelse return error.ConnectFailure;

    const wl_registry = c.wl_display_get_registry(self.wl_display);
    if (c.wl_registry_add_listener(wl_registry, &wl_registry_listener, self) < 0)
        return error.FailedToAddListener;
    if (c.wl_display_roundtrip(self.wl_display) < 0) return error.RoundtripFailed;
}

fn handleGlobal(
    data: ?*c_void,
    wl_registry: ?*c.wl_registry,
    name: u32,
    interface: ?[*:0]const u8,
    version: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    if (std.cstr.cmp(interface.?, @ptrCast([*:0]const u8, c.wl_shm_interface.name.?)) == 0) {
        const wl_shm = @ptrCast(
            *c.wl_shm,
            c.wl_registry_bind(wl_registry, name, &c.wl_shm_interface, 1),
        );
        self.server.shm.init(self.server, wl_shm);
    } else if (std.cstr.cmp(interface.?, @ptrCast([*:0]const u8, c.wl_compositor_interface.name.?)) == 0) {
        const wl_compositor = @ptrCast(
            *c.wl_compositor,
            c.wl_registry_bind(wl_registry, name, &c.wl_compositor_interface, 1),
        );
        self.server.compositor.init(self.server, wl_compositor);
    }
}

fn handleGlobalRemove(data: ?*c_void, wl_registry: ?*c.wl_registry, name: u32) callconv(.C) void {
    // Ignore
}
