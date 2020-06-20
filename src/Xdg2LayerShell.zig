const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const Server = @import("Server.zig");
const Surface = @import("Surface.zig");
const Xdg2LayerSurface = @import("Xdg2LayerSurface.zig");

const interface = c.struct_xdg_wm_base_interface{
    .destroy = requestDestroy,
    .create_positioner = requestCreatePositioner,
    .get_xdg_surface = requestGetXdgSurface,
    .pong = requestPong,
};

server: *Server,
wlr_layer_shell: *c.zwlr_layer_shell_v1,

pub fn init(self: *Self, server: *Server, wlr_layer_shell: *c.zwlr_layer_shell_v1) void {
    self.server = server;
    self.wlr_layer_shell = wlr_layer_shell;

    _ = c.wl_global_create(server.wl_display, &c.xdg_wm_base_interface, 3, self, bind) orelse
        @panic("shm init failed");
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const wl_resource = c.wl_resource_create(
        wl_client,
        &c.xdg_wm_base_interface,
        @intCast(c_int, version),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(wl_resource);
}

fn requestCreatePositioner(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, id: u32) callconv(.C) void {
    // TODO
}

fn requestGetXdgSurface(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    surface_resouce: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const surface = @intToPtr(*Surface, @ptrToInt(c.wl_resource_get_user_data(surface_resouce)));

    const xdg2layer_surface = util.allocator.create(Xdg2LayerSurface) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const xdg_surface_resource = c.wl_resource_create(
        wl_client,
        &c.xdg_surface_interface,
        c.wl_resource_get_version(wl_resource),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(xdg2layer_surface);
        return;
    };

    surface.configured = false;
    xdg2layer_surface.init(self, xdg_surface_resource, surface);
}

fn requestPong(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, serial: u32) callconv(.C) void {
    // TODO
}
