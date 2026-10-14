const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });
    const translate_c = b.dependency("translate_c", .{});
    const gtk = Translator.init(translate_c, .{
        .c_source_file = b.path("include/gtk.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{ .name = "gtk4" },
            .{ .name = "gtk4-layer-shell-0" },
        },
    });
    const log = Translator.init(translate_c, .{
        .c_source_file = b.path("include/log.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{ .name = "libnotify" },
        },
    });
    const uinput = Translator.init(translate_c, .{
        .c_source_file = b.path("include/uinput.h"),
        .target = target,
        .optimize = optimize,
    });
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "gtk",
                .module = gtk.mod,
            },
            .{
                .name = "log",
                .module = log.mod,
            },
            .{
                .name = "uinput",
                .module = uinput.mod,
            },
        },
    });
    const exe = b.addExecutable(.{
        .name = "bullseye",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
