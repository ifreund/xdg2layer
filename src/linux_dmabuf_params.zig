const buffer = @import("buffer.zig");
const c = @import("c.zig");

const interface = c.struct_zwp_linux_buffer_params_v1_interface{
    .destroy = requestDestroy,
    .add = requestAdd,
    .create = requestCreate,
    .create_immed = requestCreateImmed,
};

const listener = c.zwp_linux_buffer_params_v1_listener{
    .created = eventCreated,
    .failed = eventFailed,
};

pub fn create(wl_client: *c.wl_client, wp_linux_dmabuf: *c.zwp_linux_dmabuf_v1, version: c_int, id: u32) !void {
    const wp_linux_buffer_params = c.zwp_linux_dmabuf_v1_create_params(wp_linux_dmabuf) orelse
        return error.OutOfMemory;
    errdefer c.zwp_linux_buffer_params_v1_destroy(wp_linux_buffer_params);

    const wl_resource = c.wl_resource_create(wl_client, &c.zwp_linux_buffer_params_v1_interface, version, id) orelse
        return error.OutOfMemory;

    c.wl_resource_set_implementation(wl_resource, &interface, wp_linux_buffer_params, destroy);
    if (c.zwp_linux_buffer_params_v1_add_listener(wp_linux_buffer_params, &listener, wl_resource) < 0) unreachable;
}

fn destroy(wl_resource: ?*c.wl_resource) callconv(.C) void {
    const addr = @ptrToInt(c.wl_resource_get_user_data(wl_resource));
    const wp_linux_buffer_params = @intToPtr(*c.zwp_linux_buffer_params_v1, addr);
    c.zwp_linux_buffer_params_v1_destroy(wp_linux_buffer_params);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(wl_resource);
}

fn requestAdd(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    fd: i32,
    plane_idx: u32,
    offset: u32,
    stride: u32,
    hi: u32,
    lo: u32,
) callconv(.C) void {
    const addr = @ptrToInt(c.wl_resource_get_user_data(wl_resource));
    const wp_linux_buffer_params = @intToPtr(*c.zwp_linux_buffer_params_v1, addr);
    c.zwp_linux_buffer_params_v1_add(wp_linux_buffer_params, fd, plane_idx, offset, stride, hi, lo);
}

fn requestCreate(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    width: i32,
    height: i32,
    format: u32,
    flags: u32,
) callconv(.C) void {
    const addr = @ptrToInt(c.wl_resource_get_user_data(wl_resource));
    const wp_linux_buffer_params = @intToPtr(*c.zwp_linux_buffer_params_v1, addr);
    c.zwp_linux_buffer_params_v1_create(wp_linux_buffer_params, width, height, format, flags);
}

fn requestCreateImmed(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    width: i32,
    height: i32,
    format: u32,
    flags: u32,
) callconv(.C) void {
    const addr = @ptrToInt(c.wl_resource_get_user_data(wl_resource));
    const wp_linux_buffer_params = @intToPtr(*c.zwp_linux_buffer_params_v1, addr);
    const wl_buffer = c.zwp_linux_buffer_params_v1_create_immed(wp_linux_buffer_params, width, height, format, flags) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    _ = buffer.create(wl_client.?, wl_buffer, id) catch c.wl_client_post_no_memory(wl_client);
}

fn eventCreated(data: ?*c_void, wp_linux_buffer_params: ?*c.zwp_linux_buffer_params_v1, wl_buffer: ?*c.wl_buffer) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    const wl_client = c.wl_resource_get_client(wl_resource).?;
    const buffer_resource = buffer.create(wl_client, wl_buffer.?, 0) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    c.zwp_linux_buffer_params_v1_send_created(wl_resource, buffer_resource);
}

fn eventFailed(data: ?*c_void, wp_linux_buffer_params: ?*c.zwp_linux_buffer_params_v1) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.zwp_linux_buffer_params_v1_send_failed(wl_resource);
}
