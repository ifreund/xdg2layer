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
    self.server = server;
    self.wl_display = c.wl_display_connect(null) orelse return error.ConnectFailure;

    const wl_registry = c.wl_display_get_registry(self.wl_display);
    if (c.wl_registry_add_listener(wl_registry, &wl_registry_listener, self) < 0)
        return error.FailedToAddListener;
    if (c.wl_display_roundtrip(self.wl_display) < 0) return error.RoundtripFailed;

    const fd = c.wl_display_get_fd(self.wl_display);
    const mask = c.WL_EVENT_READABLE | c.WL_EVENT_HANGUP | c.WL_EVENT_ERROR;
    const wl_event_source = c.wl_event_loop_add_fd(
        server.wl_event_loop,
        fd,
        mask,
        dispatchEvents,
        self,
    ) orelse return error.CantAddEventSource;
    c.wl_event_source_check(wl_event_source);
}

fn dispatchEvents(fd: c_int, mask: u32, data: ?*c_void) callconv(.C) c_int {
    const self = @intToPtr(*Self, @ptrToInt(data));
    if ((mask & @as(u32, c.WL_EVENT_HANGUP) != 0) or (mask & @as(u32, c.WL_EVENT_ERROR) != 0)) {
        c.wl_display_terminate(self.server.wl_display);
        return 0;
    }

    var count: c_int = 0;

    if (mask & @as(u32, c.WL_EVENT_READABLE) != 0) count = c.wl_display_dispatch(self.wl_display);
    if (mask & @as(u32, c.WL_EVENT_WRITABLE) != 0) _ = c.wl_display_flush(self.wl_display);
    if (mask == 0) {
        count = c.wl_display_dispatch_pending(self.wl_display);
        _ = c.wl_display_flush(self.wl_display);
    }

    if (count < 0) {
        c.wl_display_terminate(self.server.wl_display);
        return 0;
    }

    return count;
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
            c.wl_registry_bind(wl_registry, name, &c.wl_shm_interface, version),
        );
        self.server.shm.init(self.server, wl_shm);
    } else if (std.cstr.cmp(interface.?, @ptrCast([*:0]const u8, c.wl_compositor_interface.name.?)) == 0) {
        const wl_compositor = @ptrCast(
            *c.wl_compositor,
            c.wl_registry_bind(wl_registry, name, &c.wl_compositor_interface, version),
        );
        self.server.compositor.init(self.server, wl_compositor);
    } else if (std.cstr.cmp(interface.?, @ptrCast([*:0]const u8, c.wl_subcompositor_interface.name.?)) == 0) {
        const wl_subcompositor = @ptrCast(
            *c.wl_subcompositor,
            c.wl_registry_bind(wl_registry, name, &c.wl_subcompositor_interface, version),
        );
        self.server.subcompositor.init(self.server, wl_subcompositor, version);
    } else if (std.cstr.cmp(interface.?, @ptrCast([*:0]const u8, c.zwlr_layer_shell_v1_interface.name.?)) == 0) {
        const wlr_layer_shell = @ptrCast(
            *c.zwlr_layer_shell_v1,
            c.wl_registry_bind(wl_registry, name, &c.zwlr_layer_shell_v1_interface, version),
        );
        self.server.xdg2layer_shell.init(self.server, wlr_layer_shell);
    }
}

fn handleGlobalRemove(data: ?*c_void, wl_registry: ?*c.wl_registry, name: u32) callconv(.C) void {
    // Ignore
}
