const std = @import("std");
const build = @import("build");

pub const Cmd = enum {
    Help,
    Version,
};

const cmds = std.StaticStringMap(Cmd).initComptime(.{
    .{ "--help", .Help },
    .{ "-h", .Help },
    .{ "--version", .Version },
    .{ "-v", .Version },
});

pub fn parse(io: std.Io, args: std.process.Args) void {
    var stdout_buffer: [256]u8 = undefined;
    var writer = std.Io.File.Writer.init(
        .stdout(),
        io,
        &stdout_buffer,
    );
    const stdout = &writer.interface;
    var iter = args.iterate();
    _ = iter.skip();
    while (iter.next()) |arg| {
        if (cmds.get(arg)) |val| {
            switch (val) {
                .Help => {
                    help(stdout);
                    stdout.flush() catch {};
                    std.process.exit(0);
                },
                .Version => {
                    _ = stdout.print(
                        "{s}\n",
                        .{build.version},
                    ) catch {};
                    stdout.flush() catch {};
                    std.process.exit(0);
                },
            }
        } else {
            exit(
                stdout,
                "Unknown argument: \x1b[31m{s}\n\n\x1b[0m",
                .{arg},
            );
        }
    }
}

fn help(stdout: *std.Io.Writer) void {
    _ = stdout.write(
        \\Usage:
        \\      bullseye [options]
        \\Options:
        \\      -h, --help        Print help
        \\      -v, --version     Print version
        \\
    ) catch {};
}

fn exit(
    stdout: *std.Io.Writer,
    comptime format: []const u8,
    args: anytype,
) noreturn {
    _ = stdout.print(format, args) catch {};
    help(stdout);
    stdout.flush() catch {};
    std.process.exit(1);
}
