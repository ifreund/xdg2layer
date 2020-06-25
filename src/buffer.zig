const c = @import("c.zig");

const interface = c.struct_wl_buffer_interface{
    .destroy = requestDestroy,
};

const listener = c.wl_buffer_listener{
    .release = eventRelease,
};

pub fn create(wl_client: *c.wl_client, wl_buffer: *c.wl_buffer, id: u32) !*c.wl_resource {
    errdefer c.wl_buffer_destroy(wl_buffer);
    const wl_resource = c.wl_resource_create(wl_client, &c.wl_buffer_interface, 1, id) orelse
        return error.OutOfMemory;
    c.wl_resource_set_implementation(wl_resource, &interface, wl_buffer, destroy);
    if (c.wl_buffer_add_listener(wl_buffer, &listener, wl_resource) < 0) unreachable;
    return wl_resource;
}

fn destroy(wl_resource: ?*c.wl_resource) callconv(.C) void {
    const wl_buffer = @intToPtr(*c.wl_buffer, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_buffer_destroy(wl_buffer);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(wl_resource);
}

fn eventRelease(data: ?*c_void, wl_buffer: ?*c.wl_buffer) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.wl_buffer_send_release(wl_resource);
}
