const Self = @This();

const c = @import("c.zig");
const util = @import("util.zig");

const listener = c.wl_callback_listener{
    .done = eventDone,
};

wl_callback: *c.wl_callback,
wl_resource: *c.wl_resource,

pub fn init(self: *Self, wl_callback: *c.wl_callback, wl_resource: *c.wl_resource) void {
    self.wl_callback = wl_callback;
    self.wl_resource = wl_resource;
    if (c.wl_callback_add_listener(wl_callback, &listener, self) < 0) @panic("failed to add listener");
}

fn eventDone(data: ?*c_void, wl_callback: ?*c.wl_callback, callback_data: u32) callconv(.C) void {
    const self = @intToPtr(*Self, @ptrToInt(data));
    c.wl_callback_send_done(self.wl_resource, callback_data);
    c.wl_resource_destroy(self.wl_resource);
    util.allocator.destroy(self);
}
