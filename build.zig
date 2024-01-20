const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const upstream = b.dependency("upstream", .{});
    const libbpf = b.dependency("libbpf", .{
        .target = target,
        .optimize = optimize,
        .zig_wa = true,
    }).artifact("bpf");
    const libxdp = b.addStaticLibrary(.{
        .name = "xdp",
        .target = target,
        .optimize = optimize,
    });
    libxdp.linkLibC();
    const cflags = [_][]const u8{ "-D_LARGEFILE64_SOURCE", "-D_FILE_OFFSET_BITS=64", "-DHAVE_SECURE_GETENV", "-DHAVE_LIBBPF_BTF__LOAD_FROM_KERNEL_BY_ID", "-DBPF_DIR_MNT=\"/sys/fs/bpf\"", "-DBPF_OBJECT_PATH=\"/usr/local/lib/bpf\"", "-DRUNDIR=\"/run\"" };
    libxdp.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "lib/libxdp/libxdp.c",
            "lib/libxdp/xsk.c",
        },
        .flags = &cflags,
    });
    libxdp.addIncludePath(.{ .dependency = .{
        .dependency = upstream,
        .sub_path = "headers",
    } });
    libxdp.addIncludePath(.{ .cwd_relative = "/usr/include/x86_64-linux-gnu/" });
    libxdp.linkLibrary(libbpf);

    const headers_path = upstream.path("headers").getPath(b);
    std.debug.print("headers path: {s}\n", .{headers_path});
    libxdp.installHeadersDirectoryOptions(.{
        .source_dir = upstream.path("headers"),
        .install_dir = .header,
        .install_subdir = "",
        // .include_extensions = &.{
        //     "libxdp.h",
        //     "xsk.h",
        // },
    });
    b.installArtifact(libxdp);
}
