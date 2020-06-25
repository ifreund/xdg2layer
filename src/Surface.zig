const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const Callback = @import("Callback.zig");
const Region = @import("Region.zig");

const interface = c.struct_wl_surface_interface{
    .destroy = requestDestroy,
    .attach = requestAttach,
    .damage = requestDamage,
    .frame = requestFrame,
    .set_opaque_region = requestSetOpaqueRegion,
    .set_input_region = requestSetInputRegion,
    .commit = requestCommit,
    .set_buffer_transform = requestSetBufferTransform,
    .set_buffer_scale = requestSetBufferScale,
    .damage_buffer = requestDamageBuffer,
};

const listener = c.wl_surface_listener{
    .enter = eventEnter,
    .leave = eventLeave,
};

wl_surface: *c.wl_surface,
wl_resource: *c.wl_resource,

configured: bool,

pub fn init(self: *Self, wl_surface: *c.wl_surface, wl_resource: *c.wl_resource) void {
    self.wl_surface = wl_surface;
    self.wl_resource = wl_resource;
    self.configured = true;
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
    if (c.wl_surface_add_listener(wl_surface, &listener, self) < 0) @panic("failed to add listener");
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_surface_destroy(self.wl_surface);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn requestAttach(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    buffer_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const wl_buffer = @intToPtr(*c.wl_buffer, @ptrToInt(c.wl_resource_get_user_data(buffer_resource)));
    c.wl_surface_attach(self.wl_surface, wl_buffer, x, y);
}

fn requestDamage(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_surface_damage(self.wl_surface, x, y, width, height);
}

fn requestFrame(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    id: u32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));

    const callback = util.allocator.create(Callback) catch {
        c.wl_client_post_no_memory(wl_client);
        return;
    };

    const callback_resource = c.wl_resource_create(wl_client, &c.wl_callback_interface, 1, id) orelse {
        c.wl_client_post_no_memory(wl_client);
        util.allocator.destroy(callback);
        return;
    };
    const wl_callback = c.wl_surface_frame(self.wl_surface).?;

    callback.init(wl_callback, callback_resource);
}

fn requestSetOpaqueRegion(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    region_resource: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const region = @intToPtr(*Region, @ptrToInt(c.wl_resource_get_user_data(region_resource)));
    c.wl_surface_set_opaque_region(self.wl_surface, region.wl_region);
}

fn requestSetInputRegion(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    region_resource: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const region = @intToPtr(*Region, @ptrToInt(c.wl_resource_get_user_data(region_resource)));
    c.wl_surface_set_input_region(self.wl_surface, region.wl_region);
}

fn requestCommit(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    if (self.configured) c.wl_surface_commit(self.wl_surface);
}

fn requestSetBufferTransform(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    transform: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_surface_set_buffer_transform(self.wl_surface, transform);
}

fn requestSetBufferScale(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    scale: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_surface_set_buffer_scale(self.wl_surface, scale);
}

fn requestDamageBuffer(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_surface_damage_buffer(self.wl_surface, x, y, width, height);
}

fn eventEnter(data: ?*c_void, wl_surface: ?*c.wl_surface, wl_output: ?*c.wl_output) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    // TODO: forward enter
    //const output = @intToPtr(*Output, @ptrToInt(c.wl_output_get_user_data(wl_output)));
    //c.wl_surface_send_enter(self.wl_resource, output.wl_output);
}

fn eventLeave(data: ?*c_void, wl_surface: ?*c.wl_surface, wl_output: ?*c.wl_output) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    // TODO: forward leave
    //const output = @intToPtr(*Output, @ptrToInt(c.wl_output_get_user_data(wl_output)));
    //c.wl_surface_send_leave(self.wl_resource, output.wl_output);
}
