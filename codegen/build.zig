const std = @import("std");

pub const components = .{.spa};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const pw_dep = b.dependency("pipewire", .{});
    inline for (components) |component| {
        const exe = b.addExecutable(.{
            .name = "codegen",
            .root_source_file = b.path("src/" ++ @tagName(component) ++ ".zig"),
            .target = target,
            .optimize = optimize,
            .strip = false,
        });
        const cmd = b.addRunArtifact(exe);
        cmd.addArg(b.graph.zig_exe);
        cmd.addDirectoryArg(pw_dep.path(""));
        const output_dir = cmd.addOutputDirectoryArg(@tagName(component));
        b.addNamedLazyPath(@tagName(component), output_dir);
    }
}
