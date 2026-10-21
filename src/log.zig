const builtin = @import("builtin");
const log = @import("log");
const std = @import("std");

pub fn init(io: std.Io) void {
    _ = log.notify_init("bullseye");
    if (builtin.mode != .debug) {
        log.notify_set_app_icon(
            "/usr/share/icons/hicolor/128x128/apps/bullseye.png",
        );
    } else {
        var buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
        var len = std.process.executableDirPath(
            io,
            &buf,
        ) catch unreachable;
        len -= 11;
        @memcpy(
            buf[len .. len + 23],
            "pkg/assets/128x128.png\x00",
        );
        log.notify_set_app_icon(&buf);
    }
}

pub fn deinit() void {
    log.notify_uninit();
}

pub fn logger(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    var buf: [128]u8 = undefined;
    const tty = 1 == std.posix.system.isatty(
        std.posix.system.STDERR_FILENO,
    );
    if (tty) {
        const io = std.Options.debug_io;
        const prev = io.swapCancelProtection(.blocked);
        defer _ = io.swapCancelProtection(prev);
        const stderr = std.debug.lockStderr(&buf).terminal();
        defer std.debug.unlockStderr();
        std.log.defaultLogFileTerminal(level, scope, format, args, stderr) catch |err| {
            std.log.err("Failed to write log message: {}", .{err});
            return;
        };
    }
    const msg = std.fmt.bufPrintSentinel(
        &buf,
        format,
        args,
        0,
    ) catch |err| {
        std.log.err("Failed to format log message: {}", .{err});
        return;
    };
    if (@intFromEnum(level) < @intFromEnum(std.log.Level.info)) {
        const note = log.notify_notification_new("bullseye", msg.ptr, null);
        _ = log.notify_notification_show(note, null);
        _ = log.g_object_unref(note);
    }
    if (tty) return;
    log.syslog(switch (level) {
        .err => log.LOG_ERR,
        .warn => log.LOG_WARNING,
        .info => log.LOG_INFO,
        .debug => log.LOG_DEBUG,
    }, "%s", msg.ptr);
}
