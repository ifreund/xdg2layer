const buffer = @import("buffer.zig");
const c = @import("c.zig");

const interface = c.struct_wl_drm_interface{
    .authenticate = requestAuthenticate,
    .create_buffer = requestCreateBuffer,
    .create_planar_buffer = requestCreatePlanarBuffer,
    .create_prime_buffer = requestCreatePrimeBuffer,
};

const listener = c.wl_drm_listener{
    .device = eventDevice,
    .format = eventFormat,
    .authenticated = eventAuthenticated,
    .capabilities = eventCapabilities,
};

var global_name: u32 = 0;

pub fn init(wl_display: *c.wl_display, wl_registry: *c.wl_registry, name: u32, version: u32) void {
    _ = c.wl_global_create(
        wl_display,
        &c.wl_drm_interface,
        @intCast(c_int, version),
        wl_registry,
        bind,
    ) orelse @panic("wl-drm init failed");
    global_name = name;
}

fn bind(wl_client: ?*c.wl_client, data: ?*c_void, version: u32, id: u32) callconv(.C) void {
    const wl_registry = @intToPtr(*c.wl_registry, @ptrToInt(data));
    create(wl_client, wl_registry, version, id) catch c.wl_client_post_no_memory(wl_client);
}

fn create(wl_client: ?*c.wl_client, wl_registry: ?*c.wl_registry, version: u32, id: u32) !void {
    const wl_drm = @ptrCast(
        ?*c.wl_drm,
        c.wl_registry_bind(wl_registry, global_name, &c.wl_drm_interface, version),
    ) orelse return error.OutOfMemory;
    errdefer c.wl_drm_destroy(wl_drm);

    const wl_resource = c.wl_resource_create(
        wl_client,
        &c.wl_drm_interface,
        @intCast(c_int, version),
        id,
    ) orelse return error.OutOfMemory;

    c.wl_resource_set_implementation(wl_resource, &interface, wl_drm, destroy);
    _ = c.wl_drm_add_listener(wl_drm, &listener, wl_resource);
}

fn destroy(wl_resource: ?*c.wl_resource) callconv(.C) void {
    const wl_drm = @intToPtr(*c.wl_drm, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_drm_destroy(wl_drm);
}

fn requestAuthenticate(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource, id: u32) callconv(.C) void {
    const wl_drm = @intToPtr(*c.wl_drm, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_drm_authenticate(wl_drm, id);
}

fn requestCreateBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    name: u32,
    width: i32,
    height: i32,
    stride: u32,
    format: u32,
) callconv(.C) void {
    const wl_drm = @intToPtr(*c.wl_drm, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const wl_buffer = c.wl_drm_create_buffer(wl_drm, name, width, height, stride, format) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    _ = buffer.create(wl_client.?, wl_buffer, id) catch c.wl_client_post_no_memory(wl_client);
}

fn requestCreatePlanarBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    name: u32,
    width: i32,
    height: i32,
    format: u32,
    offset0: i32,
    stride0: i32,
    offset1: i32,
    stride1: i32,
    offset2: i32,
    stride2: i32,
) callconv(.C) void {
    const wl_drm = @intToPtr(*c.wl_drm, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const wl_buffer = c.wl_drm_create_planar_buffer(
        wl_drm,
        name,
        width,
        height,
        format,
        offset0,
        stride0,
        offset1,
        stride1,
        offset2,
        stride2,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    _ = buffer.create(wl_client.?, wl_buffer, id) catch c.wl_client_post_no_memory(wl_client);
}

fn requestCreatePrimeBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
    name: i32,
    width: i32,
    height: i32,
    format: u32,
    offset0: i32,
    stride0: i32,
    offset1: i32,
    stride1: i32,
    offset2: i32,
    stride2: i32,
) callconv(.C) void {
    const wl_drm = @intToPtr(*c.wl_drm, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const wl_buffer = c.wl_drm_create_prime_buffer(
        wl_drm,
        name,
        width,
        height,
        format,
        offset0,
        stride0,
        offset1,
        stride1,
        offset2,
        stride2,
    ) orelse {
        c.wl_client_post_no_memory(wl_client);
        return;
    };
    _ = buffer.create(wl_client.?, wl_buffer, id) catch c.wl_client_post_no_memory(wl_client);
}

fn eventDevice(data: ?*c_void, wl_drm: ?*c.wl_drm, name: ?[*:0]const u8) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.wl_drm_send_device(wl_resource, name);
}

fn eventFormat(data: ?*c_void, wl_drm: ?*c.wl_drm, format: u32) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.wl_drm_send_format(wl_resource, format);
}

fn eventAuthenticated(data: ?*c_void, wl_drm: ?*c.wl_drm) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.wl_drm_send_authenticated(wl_resource);
}

fn eventCapabilities(data: ?*c_void, wl_drm: ?*c.wl_drm, value: u32) callconv(.C) void {
    const wl_resource = @intToPtr(*c.wl_resource, @ptrToInt(data));
    c.wl_drm_send_capabilities(wl_resource, value);
}
