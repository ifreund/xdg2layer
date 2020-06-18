const Self = @This();

const std = @import("std");
const c = @import("c.zig");
const util = @import("util.zig");

const Server = @import("Server.zig");
const ShmPool = @import("ShmPool.zig");

const interface = c.struct_wl_shm_interface{
    .create_pool = requestCreatePool,
};

wl_shm: *c.wl_shm,

pub fn init(self: *Self, server: *Server, wl_shm: *c.wl_shm) void {
    self.wl_shm = wl_shm;

    _ = c.wl_global_create(server.wl_display, &c.wl_shm_interface, 1, self, bind) orelse
        @panic("shm init failed");
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));

    const wl_resource = c.wl_resource_create(wl_client, &c.wl_shm_interface, 1, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);

    // TODO: listen for format event forward other formats
    c.wl_shm_send_format(wl_resource, c.WL_SHM_FORMAT_ARGB8888);
    c.wl_shm_send_format(wl_resource, c.WL_SHM_FORMAT_XRGB8888);
}

fn requestCreatePool(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    fd: i32,
    size: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));

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
