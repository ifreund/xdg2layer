pub usingnamespace @cImport({
    @cDefine("_POSIX_C_SOURCE", "200809L");

    @cInclude("stdlib.h");

    @cInclude("wayland-client-core.h");
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-server-core.h");
    @cInclude("wayland-server-protocol.h");

    @cInclude("linux-dmabuf-unstable-v1-protocol.h");
    @cInclude("wayland-drm-protocol.h");
    @cInclude("xdg-shell-protocol.h");

    @cInclude("linux-dmabuf-unstable-v1-client-protocol.h");
    @cInclude("wayland-drm-client-protocol.h");
    @cInclude("wlr-layer-shell-unstable-v1-client-protocol.h");
});
