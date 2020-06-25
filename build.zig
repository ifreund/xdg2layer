const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const scan_protocols = ScanProtocolsStep.create(b);

    const exe = b.addExecutable("xdg2layer", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.linkLibC();
    exe.linkSystemLibrary("wayland-server");
    exe.linkSystemLibrary("wayland-client");

    exe.step.dependOn(&scan_protocols.step);
    exe.addIncludeDir("protocol");
    exe.addCSourceFile("protocol/wlr-layer-shell-unstable-v1-protocol.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("protocol/xdg-shell-protocol.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("protocol/linux-dmabuf-unstable-v1-protocol.c", &[_][]const u8{"-std=c99"});

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const ScanProtocolsStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,

    fn create(builder: *std.build.Builder) *ScanProtocolsStep {
        const self = builder.allocator.create(ScanProtocolsStep) catch unreachable;
        self.* = init(builder);
        return self;
    }

    fn init(builder: *std.build.Builder) ScanProtocolsStep {
        return ScanProtocolsStep{
            .builder = builder,
            .step = std.build.Step.init("Scan Protocols", builder.allocator, make),
        };
    }

    fn make(step: *std.build.Step) !void {
        const self = @fieldParentPtr(ScanProtocolsStep, "step", step);

        const protocol_dir = std.fmt.trim(try self.builder.exec(
            &[_][]const u8{ "pkg-config", "--variable=pkgdatadir", "wayland-protocols" },
        ));

        const protocol_dir_paths = [_][]const []const u8{
            &[_][]const u8{ protocol_dir, "stable/xdg-shell/xdg-shell.xml" },
            &[_][]const u8{ protocol_dir, "unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml" },
            &[_][]const u8{ "protocol", "wlr-layer-shell-unstable-v1.xml" },
        };

        const server_protocols = [_][]const u8{
            "linux-dmabuf-unstable-v1",
            "xdg-shell",
        };

        const client_protocols = [_][]const u8{
            "linux-dmabuf-unstable-v1",
            "wlr-layer-shell-unstable-v1",
        };

        for (protocol_dir_paths) |dir_path| {
            const xml_in_path = try std.fs.path.join(self.builder.allocator, dir_path);

            // Extension is .xml, so slice off the last 4 characters
            const basename = std.fs.path.basename(xml_in_path);
            const basename_no_ext = basename[0..(basename.len - 4)];

            const code_out_path = try std.mem.concat(
                self.builder.allocator,
                u8,
                &[_][]const u8{ "protocol/", basename_no_ext, "-protocol.c" },
            );
            _ = try self.builder.exec(
                &[_][]const u8{ "wayland-scanner", "private-code", xml_in_path, code_out_path },
            );

            for (server_protocols) |server_protocol| {
                if (std.mem.eql(u8, basename_no_ext, server_protocol)) {
                    const header_out_path = try std.mem.concat(
                        self.builder.allocator,
                        u8,
                        &[_][]const u8{ "protocol/", basename_no_ext, "-protocol.h" },
                    );
                    _ = try self.builder.exec(
                        &[_][]const u8{ "wayland-scanner", "server-header", xml_in_path, header_out_path },
                    );
                }
            }

            for (client_protocols) |client_protocol| {
                if (std.mem.eql(u8, basename_no_ext, client_protocol)) {
                    const header_out_path = try std.mem.concat(
                        self.builder.allocator,
                        u8,
                        &[_][]const u8{ "protocol/", basename_no_ext, "-client-protocol.h" },
                    );
                    _ = try self.builder.exec(
                        &[_][]const u8{ "wayland-scanner", "client-header", xml_in_path, header_out_path },
                    );
                }
            }
        }
    }
};
