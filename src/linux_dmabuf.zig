const c = @import("c.zig");
const linux_dmabuf_params = @import("linux_dmabuf_params.zig");

const interface = c.struct_zwp_linux_dmabuf_v1_interface{
    .destroy = requestDestroy,
    .create_params = requestCreateParams,
};

const listener = c.zwp_linux_dmabuf_v1_listener{
    .format = eventFormat,
    .modifier = eventModifier,
};

var global_name: u32 = 0;

pub fn init(wl_display: *c.wl_display, wl_registry: *c.wl_registry, name: u32, version: u32) void {
    _ = c.wl_global_create(
        wl_display,
        &c.zwp_linux_dmabuf_v1_interface,
        @intCast(c_int, version),
        wl_registry,
        bind,
    ) orelse @panic("linux-dmabuf init failed");
    global_name = name;
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const wl_registry = @intToPtr(*c.wl_registry, @ptrToInt(data));
    create(wl_client, wl_registry, version, id) catch c.wl_client_post_no_memory(wl_client);
}

fn create(wl_client: ?*c.wl_client, wl_registry: ?*c.wl_registry, version: u32, id: u32) !void {
    const wp_linux_dmabuf = @ptrCast(
        ?*c.zwp_linux_dmabuf_v1,
        c.wl_registry_bind(wl_registry, global_name, &c.zwp_linux_dmabuf_v1_interface, version),
    ) orelse return error.OutOfMemory;
    errdefer c.zwp_linux_dmabuf_v1_destroy(wp_linux_dmabuf);

    const wl_resource = c.wl_resource_create(
        wl_client,
        &c.zwp_linux_dmabuf_v1_interface,
        @intCast(c_int, version),
        id,
    ) orelse return error.OutOfMemory;

    c.wl_resource_set_implementation(wl_resource, &interface, wp_linux_dmabuf, destroy);
    _ = c.zwp_linux_dmabuf_v1_add_listener(wp_linux_dmabuf, &listener, wl_resource);
}

fn destroy(wl_resource: ?*c.wl_resource) callconv(.C) void {
    const wp_linux_dmabuf = @intToPtr(*c.zwp_linux_dmabuf_v1, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.zwp_linux_dmabuf_v1_destroy(wp_linux_dmabuf);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(wl_resource);
}

fn requestCreateParams(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, id: u32) callconv(.C) void {
    const wp_linux_dmabuf = @intToPtr(*c.zwp_linux_dmabuf_v1, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    linux_dmabuf_params.create(wl_client.?, wp_linux_dmabuf, c.wl_resource_get_version(wl_resource), id) catch
        c.wl_client_post_no_memory(wl_client);
}

fn eventFormat(data: ?*c_void, wp_linux_dmabuf: ?*c.zwp_linux_dmabuf_v1, format: u32) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.zwp_linux_dmabuf_v1_send_format(wl_resource, format);
}

fn eventModifier(data: ?*c_void, wp_linux_dmabuf: ?*c.zwp_linux_dmabuf_v1, format: u32, hi: u32, lo: u32) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.zwp_linux_dmabuf_v1_send_modifier(wl_resource, format, hi, lo);
}
