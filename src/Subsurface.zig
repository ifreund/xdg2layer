const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const Surface = @import("Surface.zig");

const interface = c.struct_wl_subsurface_interface{
    .destroy = requestDestroy,
    .set_position = requestSetPosition,
    .place_above = requestPlaceAbove,
    .place_below = requestPlaceBelow,
    .set_sync = requestSetSync,
    .set_desync = requestSetDesync,
};

wl_subsurface: *c.wl_subsurface,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_subsurface: *c.wl_subsurface, wl_resource: *c.wl_resource) void {
    self.wl_subsurface = wl_subsurface;
    self.wl_resource = wl_resource;
    c.wl_resource_set_implementation(wl_resource, &interface, self, null);
}

fn requestDestroy(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_subsurface_destroy(self.wl_subsurface);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}

fn requestSetPosition(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    x: i32,
    y: i32,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_subsurface_set_position(self.wl_subsurface, x, y);
}

fn requestPlaceAbove(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    surface_resouce: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const surface = @intToPtr(*Surface, @ptrToInt(c.wl_resource_get_user_data(surface_resouce)));
    c.wl_subsurface_place_above(self.wl_subsurface, surface.wl_surface);
}

fn requestPlaceBelow(
    wl_client: ?*c.wl_client,
    wl_resource: ?*c.wl_resource,
    surface_resouce: ?*c.wl_resource,
) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    const surface = @intToPtr(*Surface, @ptrToInt(c.wl_resource_get_user_data(surface_resouce)));
    c.wl_subsurface_place_below(self.wl_subsurface, surface.wl_surface);
}

fn requestSetSync(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_subsurface_set_sync(self.wl_subsurface);
}

fn requestSetDesync(wl_client: ?*c.wl_client, wl_resource: ?*c.wl_resource) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(c.wl_resource_get_user_data(wl_resource)));
    c.wl_subsurface_set_desync(self.wl_subsurface);
}
