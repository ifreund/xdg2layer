const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const interface = c.struct_wl_region_interface{
    .destroy = requestDestroy,
    .add = requestAdd,
    .subtract = requestSubtract,
};

wl_region: *c.wl_region,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_region: *c.wl_region, wl_resource: *c.wl_resource) void {
    self.wl_region = wl_region;
    self.wl_resource = wl_resource;
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_region_destroy(self.wl_region);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn requestAdd(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_region_add(self.wl_region, x, y, width, height);
}

fn requestSubtract(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_region_subtract(self.wl_region, x, y, width, height);
}
