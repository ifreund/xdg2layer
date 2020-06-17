const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const interface = c.struct_wl_buffer_interface{
    .destroy = requestDestroy,
};

const listener = c.wl_buffer_listener{
    .release = eventRelease,
};

wl_buffer: *c.wl_buffer,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_buffer: *c.wl_buffer, wl_resource: *c.wl_resource) void {
    self.wl_buffer = wl_buffer;
    self.wl_resource = wl_resource;
    c.wl_resource_set_implementation(&wl_resource, &interface, self, null);
    if (c.wl_buffer_add_listener(&wl_buffer, &listener, self) < 0) @panic("failed to add listener");
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_buffer_destroy(self.wl_buffer);
    c.wl_resouce_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn eventRelease(data: ?*c_void, wl_buffer: *c.wl_buffer) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    wl_buffer_send_release(welf.wl_resource);
}
