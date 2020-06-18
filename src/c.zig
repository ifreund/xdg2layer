pub usingnamespace @cImport({
    @cDefine("_POSIX_C_SOURCE", "200809L");
    @cInclude("stdlib.h");
    @cInclude("wayland-client.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-server-core.h");
    @cInclude("wayland-server-protocol.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
    @cInclude("xdg-shell-protocol.h");
});
