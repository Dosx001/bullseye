const log = @import("log.zig");
const std = @import("std");
const win = @import("window.zig");
const cli = @import("cli.zig");

pub const std_options = std.Options{
    .logFn = log.logger,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    log.init(io);
    defer log.deinit();
    cli.parse(io, init.minimal.args);
    win.init();
}
