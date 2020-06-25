const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");
const buffer = @import("buffer.zig");

const interface = c.struct_wl_shm_pool_interface{
    .create_buffer = requestCreateBuffer,
    .destroy = requestDestroy,
    .resize = requestResize,
};

wl_shm_pool: *c.wl_shm_pool,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_shm_pool: *c.wl_shm_pool, wl_resource: *c.wl_resource) void {
    self.wl_shm_pool = wl_shm_pool;
    self.wl_resource = wl_resource;
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
}

fn requestCreateBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    offset: i32,
    width: i32,
    height: i32,
    stride: i32,
    format: u32,
) callconv(.C) void {
    const wl_shm_pool = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource))).wl_shm_pool;

    const wl_buffer = c.wl_shm_pool_create_buffer(wl_shm_pool, offset, width, height, stride, format) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    _ = buffer.create(wl_client.?, wl_buffer, id) catch c.wl_client_post_no_memory(wl_client);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_shm_pool_destroy(self.wl_shm_pool);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn requestResize(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, size: i32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_shm_pool_resize(self.wl_shm_pool, size);
}
