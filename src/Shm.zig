const Self = @This();

const std = @import("std");
const c = @import("c.zig");
const util = @import("util.zig");

const Client = @import("Client.zig");
const Server = @import("Server.zig");

const interface = c.struct_wl_shm_interface{
    .create_pool = requestCreatePool,
};

wl_shm: *c.wl_shm,

pub fn init(self: *Self, server: *Server, client: *Client, wl_shm: *c.wl_shm) !void {
    self.wl_shm = wl_shm;

    wl_global_create(server.wl_display, &wl_shm_interface, 1, self, bind) orelse
        return error.CantCreateWlGlobal;
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const wl_resource = c.wl_resource_create(wl_client, &c.wl_shm_interface, 1, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    c.wl_resource_set_implementation(wl_resource, &interface, self);

    // TODO: listen for format event forward other formats
    wl_shm_send_format(resource, WL_SHM_FORMAT_ARGB8888);
    wl_shm_send_format(resource, WL_SHM_FORMAT_XRGB8888);
}

fn requestCreatePool(
    wl_client: *c.wl_client,
    wl_resource: *c.wl_resource,
    id: u32,
    fd: i32,
    size: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const shm_pool = util.allocator.create(ShmPool) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const pool_resource = c.wl_resource_create(wl_client, &c.wl_shm_pool_interface, 1, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(shm_pool);
        return;
    };
    const wl_shm_pool = c.wl_shm_create_pool(self.wl_shm, fd, size).?;

    shm_pool.init(wl_shm_pool, pool_resource);
}
