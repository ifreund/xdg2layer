const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const Server = @import("Server.zig");
const Subsurface = @import("Subsurface.zig");
const Surface = @import("Surface.zig");

const interface = c.struct_wl_subcompositor_interface{
    .destroy = requestDestroy,
    .get_subsurface = requestGetSubsurface,
};

wl_subcompositor: *c.wl_subcompositor,

pub fn init(self: *Self, server: *Server, wl_subcompositor: *c.wl_subcompositor, version: u32) void {
    self.wl_subcompositor = wl_subcompositor;

    _ = c.wl_global_create(
        server.wl_display,
        &c.wl_subcompositor_interface,
        @intCast(c_int, version),
        self,
        bind,
    ) orelse @panic("subcompositor init failed");
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const wl_resource = c.wl_resource_create(
        wl_client,
        &c.wl_subcompositor_interface,
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

fn requestGetSubsurface(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    surface_resource: ?*c.wl_resource,
    parent_resource: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const surface = @intToPtr(*Surface, @ptrToInt(c.wl_resource_get_user_data(surface_resource)));
    const parent = @intToPtr(*Surface, @ptrToInt(c.wl_resource_get_user_data(parent_resource)));

    const subsurface = util.allocator.create(Subsurface) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const subsurface_resource = c.wl_resource_create(
        wl_client,
        &c.wl_subsurface_interface,
        c.wl_resource_get_version(wl_resource),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(subsurface);
        return;
    };
    const wl_subsurface = c.wl_subcompositor_get_subsurface(
        self.wl_subcompositor,
        surface.wl_surface,
        parent.wl_surface,
    ).?;

    subsurface.init(wl_subsurface, subsurface_resource);
}
