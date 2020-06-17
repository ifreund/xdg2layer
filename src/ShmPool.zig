const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const interface = c.struct_wl_shm_pool_interface{
    .create_buffer = handleCreateBuffer,
    .destroy = handleDestroy,
    .resize = hanldeResize,
};

wl_shm_pool: *c.wl_shm_pool,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_shm_pool: *c.wl_shm_pool, wl_resource: *c.wl_resource) void {
    self.wl_shm_pool = wl_shm_pool;
    self.wl_resource = wl_resource;
    c.wl_resource_set_implementation(&wl_resource, &interface, self, null);
}

fn handleCreateBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    offset: i32,
    width: i32,
    height: i32,
    stride: i32,
    format: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));

    const buffer = util.allocator.create(Buffer);
    const buffer_resource = c.wl_resource_create(wl_client, &c.wl_buffer_interface, 1, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(Buffer);
        return;
    };
    const wl_buffer = c.wl_shm_pool_create_buffer(self.wl_shm_pool, offset, width, height, stride, format).?;

    buffer.init(wl_buffer, buffer_resource);
}

fn handleDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_shm_pool_destroy(self.wl_shm_pool);
    c.wl_resouce_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn handleResize(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, size: i32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_shm_pool_resize(self.wl_shm_pool, size);
}
