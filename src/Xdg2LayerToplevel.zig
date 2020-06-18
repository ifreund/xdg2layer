const Self = @This();

const std = @import("std");

const c = @import("c.zig");
const util = @import("util.zig");

const Xdg2LayerSurface = @import("Xdg2LayerSurface.zig");

const interface = c.struct_xdg_toplevel_interface{
    .destroy = requestDestroy,
    .set_parent = requestSetParent,
    .set_title = requestSetTitle,
    .set_app_id = requestSetAppId,
    .show_window_menu = requestShowWindowMenu,
    .move = requestMove,
    .resize = requestResize,
    .set_max_size = requestSetMaxSize,
    .set_min_size = requestSetMinSize,
    .set_maximized = requestSetMaximized,
    .unset_maximized = requestUnsetMaximized,
    .set_fullscreen = requestSetFullscreen,
    .unset_fullscreen = requestUnsetFullscreen,
    .set_minimized = requestSetMinimized,
};

const listener = c.zwlr_layer_surface_v1_listener{
    .configure = eventConfigure,
    .closed = eventClosed,
};

xdg2layer_surface: *Xdg2LayerSurface,
wlr_layer_surface: *c.zwlr_layer_surface_v1,
wl_resource: *c.wl_resource,

/// Current dimesions of the xdg toplevel
current_width: u32,
current_height: u32,

/// Pending dimensions of the xdg toplevel, the dimensions most recently
/// received in the layer_surface configure event
pending_width: u32,
pending_height: u32,

/// Map of xdg_surface to layer_surface configure serial
serial_map: std.AutoHashMap(u32, u32),

pub fn init(
    self: *Self,
    xdg2layer_surface: *Xdg2LayerSurface,
    wlr_layer_surface: *c.zwlr_layer_surface_v1,
    wl_resource: *c.wl_resource,
) void {
    self.xdg2layer_surface = xdg2layer_surface;
    self.wlr_layer_surface = wlr_layer_surface;
    self.wl_resource = wl_resource;
    self.serial_map = std.AutoHashMap(u32, u32).init(util.allocator);
    if (c.zwlr_layer_surface_v1_add_listener(wlr_layer_surface, &listener, self) < 0)
        @panic("failed to add layer surface listener");
}

pub fn handleAckConfigure(self: *Self, serial: u32) void {
    const layer_serial = self.serial_map.remove(serial).?.value;
    c.zwlr_layer_surface_v1_ack_configure(self.wlr_layer_surface, layer_serial);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_resource_destroy(self.wl_resource);
    c.zwlr_layer_surface_v1_destroy(self.wlr_layer_surface);
    self.xdg2layer_surface.role = .none;
    self.serial_map.deinit();
}

// ignore these requests
fn requestSetParent(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, parent_resource: ?*c.wl_resource) callconv(.C) void {}
fn requestSetTitle(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, title: ?[*:0]const u8) callconv(.C) void {}
fn requestSetAppId(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, app_id: ?[*:0]const u8) callconv(.C) void {}
fn requestShowWindowMenu(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, serial: u32, x: i32, y: i32) callconv(.C) void {}
fn requestMove(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, serial: u32) callconv(.C) void {}
fn requestResize(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, serial: u32, edges: u32) callconv(.C) void {}
fn requestSetMaxSize(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, width: i32, height: i32) callconv(.C) void {}
fn requestSetMinSize(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, width: i32, height: i32) callconv(.C) void {}
fn requestSetMaximized(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {}
fn requestUnsetMaximized(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {}
fn requestSetFullscreen(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, wl_output: ?*c.wl_output) callconv(.C) void {}
fn requestUnsetFullscreen(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {}
fn requestSetMinimized(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {}

fn eventConfigure(data: ?*c_void, wlr_layer_surface: ?*c.zwlr_layer_surface_v1, serial: u32, width: u32, height: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    const server = self.xdg2layer_surface.xdg2layer_shell.server;

    // if the xdg toplevel is already the right size or has been told to take
    // the right size, ack and return
    if ((width == self.current_width and height == self.current_height) or
        (width == self.pending_width and height == self.pending_height))
    {
        c.zwlr_layer_surface_v1_ack_configure(wlr_layer_surface, serial);
        return;
    }

    const next_serial = c.wl_display_next_serial(server.wl_display);
    self.serial_map.putNoClobber(serial, next_serial) catch return;

    var states = [_]u32{@as(u32, c.XDG_TOPLEVEL_STATE_MAXIMIZED)};
    var wl_array = c.wl_array{
        .size = @sizeOf(@TypeOf(states)),
        .alloc = @sizeOf(@TypeOf(states)),
        .data = &states,
    };
    c.xdg_toplevel_send_configure(self.wl_resource, @intCast(i32, width), @intCast(i32, height), &wl_array);
    c.xdg_surface_send_configure(self.xdg2layer_surface.wl_resource, next_serial);
}

fn eventClosed(data: ?*c_void, wlr_layer_surface: ?*c.zwlr_layer_surface_v1) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    c.xdg_toplevel_send_close(self.wl_resource);
}
