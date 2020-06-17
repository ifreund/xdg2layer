const Self = @This();

const c = @import("c.zig");

wl_display: *c.wl_display,
wl_event_loop: *c.wl_event_loop,

shm: Shm,

pub fn init(self: *Self) !void {
    self.wl_display = c.wl_display_create() orelse return error.OutOfMemory;

    // Never returns null if the display was created successfully
    self.wl_event_loop = c.wl_display_get_event_loop(self.wl_display).?;
}

pub fn deinit(self: Self) void {
    c.wl_display_destroy(self.wl_display);
}

/// Create the socket, set WAYLAND_DISPLAY
pub fn start(self: Self) !void {
    const socket = c.wl_display_add_socket_auto(self.wl_display) orelse return error.CantAddSocket;
    if (c.setenv("WAYLAND_DISPLAY", socket, 1) < 0) return error.CantSetEnv;
}

/// Enter the wayland event loop and block until the program is exited
pub fn run(self: *Self) void {
    c.wl_display_run(self.wl_display);
}
