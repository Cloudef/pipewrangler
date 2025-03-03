const std = @import("std");
const codegen_components = @import("codegen").components;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var opts = b.addOptions();
    const debug = b.option(bool, "debug", "enable debug prints") orelse false;
    opts.addOption(bool, "debug", debug);

    const pipewrangler = b.addModule("pipewrangler", .{
        .root_source_file = b.path("src/pipewrangler.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });
    pipewrangler.addImport("build_options", opts.createModule());

    const run_all = b.step("example", "Run all examples");
    inline for (.{ .dump, .query }) |example| {
        const exe = b.addExecutable(.{
            .name = @tagName(example),
            .root_source_file = b.path("examples/" ++ @tagName(example) ++ ".zig"),
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
            .strip = false,
        });
        exe.root_module.addImport("pipewrangler", pipewrangler);
        const install = b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "example" } } });
        b.getInstallStep().dependOn(&install.step);
        var cmd = makeRunStep(b, exe, "example:" ++ @tagName(example), "Run " ++ @tagName(example) ++ " example");
        run_all.dependOn(&cmd.step);
    }

    const test_filter = b.option([]const u8, "test-filter", "Skip tests that do not match any filter") orelse "";
    const test_step = b.step("test", "Run unit tests");
    inline for (.{.pipewrangler}) |mod| {
        const tst = b.addTest(.{
            .root_source_file = b.path("src/" ++ @tagName(mod) ++ ".zig"),
            .target = target,
            .optimize = optimize,
            .filters = &.{test_filter},
            .link_libc = pipewrangler.link_libc,
            .single_threaded = true,
            .strip = false,
        });
        var cmd = makeRunStep(b, tst, "test:" ++ @tagName(mod), "Run " ++ @tagName(mod) ++ " tests");
        test_step.dependOn(&cmd.step);
    }

    // XXX: lazy steps not possible with steps <https://github.com/ziglang/zig/issues/21525>
    const enable_codegen = b.option(bool, "codegen", "enable codegen") orelse false;

    if (enable_codegen) {
        if (b.lazyDependency("codegen", .{})) |codegen| {
            const codegen_all = b.step("codegen", "Run all codegen steps");
            inline for (codegen_components) |component| {
                const dir = codegen.namedLazyPath(@tagName(component));
                const install = b.addInstallDirectory(.{
                    .source_dir = dir,
                    .install_dir = .{ .custom = @tagName(component) },
                    .install_subdir = "generated",
                });
                var run = b.step("codegen:" ++ @tagName(component), "Generate code for " ++ @tagName(component) ++ " component");
                run.dependOn(&install.step);
                codegen_all.dependOn(&install.step);
            }
        }
    }
}

fn makeRunStep(b: *std.Build, step: *std.Build.Step.Compile, name: []const u8, description: []const u8) *std.Build.Step.Run {
    const cmd = b.addRunArtifact(step);
    if (b.args) |args| cmd.addArgs(args);
    const run = b.step(name, description);
    run.dependOn(&cmd.step);
    return cmd;
}
