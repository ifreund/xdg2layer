const Self = @This();

const std = @import("std");
const c = @import("c.zig");
const util = @import("util.zig");

const Client = @import("Client.zig");
const Region = @import("Region.zig");
const Server = @import("Server.zig");
const Surface = @import("Surface.zig");

const interface = c.struct_wl_shm_interface{
    .create_surface = requestCreateSurface,
    .create_region = requestCreateRegion,
};

wl_compositor: *c.wl_compositor,

pub fn init(self: *Self, server: *Server, wl_compositor: *c.wl_compositor) void {
    self.wl_compositor = wl_compositor;

    wl_global_create(server.wl_display, &wl_compositor_interface, 4, self, bind) orelse
        @panic("compositor init failed");
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const wl_resource = c.wl_resource_create(wl_client, &c.wl_compositor_interface, version, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    c.wl_resource_set_implementation(wl_resource, &interface, self);
}

fn requestCreateSurface(
    wl_client: *c.wl_client,
    wl_resource: *c.wl_resource,
    id: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const surface = util.allocator.create(Surface) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const surface_resource = c.wl_resource_create(
        wl_client,
        &c.wl_surface_interface,
        c.wl_resource_get_version(wl_resource),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(surface);
        return;
    };
    const wl_surface = c.wl_compositor_create_surface(self.wl_compositor).?;

    surface.init(wl_surface, surface_resource);
}

fn requestCreateRegion(
    wl_client: *c.wl_client,
    wl_resource: *c.wl_resource,
    id: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const region = util.allocator.create(Region) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const region_resource = c.wl_resource_create(
        wl_client,
        &c.wl_region_interface,
        c.wl_resource_get_version(wl_resource),
        id,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(region);
        return;
    };
    const wl_region = c.wl_compositor_create_region(self.wl_compositor).?;

    region.init(wl_region, region_resource);
}
