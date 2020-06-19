const Self = @This();

const std = @import("std");

const c = @import("c.zig");
const util = @import("util.zig");

const Surface = @import("Surface.zig");
const Xdg2LayerShell = @import("Xdg2LayerShell.zig");
const Xdg2LayerToplevel = @import("Xdg2LayerToplevel.zig");

const Role = union(enum) {
    toplevel: Xdg2LayerToplevel,
    // TODO: implement popups
    popup: void,
    none: void,
};

const interface = c.struct_xdg_surface_interface{
    .destroy = requestDestroy,
    .get_toplevel = requestGetToplevel,
    .get_popup = requestGetPopup,
    .set_window_geometry = requestSetWindowGeometry,
    .ack_configure = requestAckConfigure,
};

xdg2layer_shell: *Xdg2LayerShell,
surface: *Surface,
wl_resource: *c.wl_resource,
role: Role,

pub fn init(self: *Self, xdg2layer_shell: *Xdg2LayerShell, wl_resource: *c.wl_resource, surface: *Surface) void {
    self.xdg2layer_shell = xdg2layer_shell;
    self.wl_resource = wl_resource;
    self.surface = surface;
    self.role = .none;
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    std.debug.assert(self.role == .none);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn requestGetToplevel(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));

    const xdg2layer_toplevel = util.allocator.create(Xdg2LayerToplevel) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const toplevel_resource = c.wl_resource_create(
        wl_client,
        &c.xdg_toplevel_interface,
        c.wl_resource_get_version(wl_resource),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(xdg2layer_toplevel);
        return;
    };

    const wlr_layer_surface = c.zwlr_layer_shell_v1_get_layer_surface(
        self.xdg2layer_shell.wlr_layer_shell,
        self.surface.wl_surface,
        null,
        c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
        "xdg2layer",
    ).?;

    xdg2layer_toplevel.init(self, wlr_layer_surface, toplevel_resource);
}

fn requestGetPopup(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    parent_resource: ?*c.wl_resource,
    positioner_resource: ?*c.wl_resource,
) callconv(.C) void {
    // TODO
}

// Ignore the request
fn requestSetWindowGeometry(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) callconv(.C) void {}

fn requestAckConfigure(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    serial: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    switch (self.role) {
        .toplevel => |*t| t.handleAckConfigure(serial),
        .popup, .none => {},
    }
}
