const go = @import("gobject.zig");
const std = @import("std");
const gtk = @import("gtk");
const uinput = @import("uinput");

const Region = struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

const chars = [9]u8{
    'w', 's', 'e',
    'a', ' ', 'f',
    'i', 'd', 'o',
};

var index: usize = 0;
var regions: [10]Region = undefined;
var grid_box: [*c]gtk.GtkGrid = undefined;
var grid_label: [*c]gtk.GtkGrid = undefined;
var window: [*c]gtk.GtkWindow = undefined;
var controller: ?*gtk.GtkEventController = undefined;

pub fn init() void {
    const app = gtk.gtk_application_new(
        "com.github.dosx001.bullseye",
        gtk.G_APPLICATION_DEFAULT_FLAGS,
    );
    go.gSignalConnect(
        app,
        "activate",
        gtk.G_CALLBACK(activate),
        null,
    );
    controller = gtk.gtk_shortcut_controller_new();
    shortcuts();
    _ = gtk.g_application_run(@ptrCast(app), 0, null);
    defer gtk.g_object_unref(app);
}

fn activate(
    app: [*c]gtk.GtkApplication,
    _: gtk.gpointer,
) callconv(.c) void {
    const display = gtk.gdk_display_get_default();
    defer gtk.g_object_unref(display);
    const monitors = gtk.gdk_display_get_monitors(display);
    const monitor: ?*gtk.GdkMonitor = @ptrCast(
        gtk.g_list_model_get_item(
            monitors,
            0,
        ),
    );
    defer gtk.g_object_unref(monitor);
    var rect: gtk.GdkRectangle = undefined;
    gtk.gdk_monitor_get_geometry(
        monitor,
        &rect,
    );
    const provider = gtk.gtk_css_provider_new();
    window = @ptrCast(
        gtk.gtk_application_window_new(app),
    );
    gtk.gtk_window_fullscreen(window);
    go.gSignalConnect(
        window,
        "notify::is-active",
        gtk.G_CALLBACK(check_focus),
        null,
    );
    gtk.gtk_css_provider_load_from_data(
        provider,
        @embedFile("styles.css"),
        -1,
    );
    gtk.gtk_style_context_add_provider_for_display(
        display,
        @ptrCast(provider),
        gtk.GTK_STYLE_PROVIDER_PRIORITY_USER,
    );
    regions[index] = .{
        .x = 0,
        .y = 0,
        .width = rect.width,
        .height = rect.height,
    };
    grid_box = @ptrCast(gtk.gtk_grid_new());
    _ = gtk.g_object_ref_sink(grid_box);
    inline for (0..9) |i| {
        const box = gtk.gtk_box_new(
            gtk.GTK_ORIENTATION_VERTICAL,
            0,
        );
        const label = gtk.gtk_label_new(&[2]u8{ chars[i], 0 });
        gtk.gtk_widget_set_size_request(label, 16, 16);
        gtk.gtk_widget_add_css_class(label, "key");
        gtk.gtk_widget_set_halign(label, gtk.GTK_ALIGN_CENTER);
        gtk.gtk_widget_set_valign(label, gtk.GTK_ALIGN_CENTER);
        gtk.gtk_widget_set_vexpand(label, 1);
        gtk.gtk_box_append(@ptrCast(box), @ptrCast(label));
        gtk.gtk_grid_attach(
            grid_box,
            box,
            @intCast(i % 3),
            @intCast(i / 3),
            1,
            1,
        );
    }
    update_size();
    gtk.gtk_widget_add_controller(@ptrCast(window), controller);
    gtk.gtk_window_set_child(window, @ptrCast(grid_box));
    gtk.gtk_window_present(window);
    grid_label = @ptrCast(gtk.gtk_grid_new());
    _ = gtk.g_object_ref_sink(grid_label);
    inline for (0..9) |i| {
        const label = gtk.gtk_label_new("•");
        gtk.gtk_grid_attach(
            grid_label,
            label,
            @intCast(i % 3),
            @intCast(i / 3),
            1,
            1,
        );
    }
}

fn check_focus(
    _: [*c]gtk.GObject,
    _: [*c]gtk.GParamSpec,
    _: gtk.gpointer,
) callconv(.c) void {
    if (gtk.gtk_window_is_active(window) != 1) {
        gtk.g_application_quit(@ptrCast(
            gtk.gtk_window_get_application(
                window,
            ),
        ));
    }
}

fn update_size() void {
    const grid = blk: switch (index) {
        0 => {
            gtk.gtk_window_set_child(
                window,
                @ptrCast(grid_box),
            );
            break :blk grid_box;
        },
        1 => {
            gtk.gtk_window_set_child(
                window,
                @ptrCast(grid_label),
            );
            break :blk grid_label;
        },
        else => grid_label,
    };
    const rect = regions[index];
    gtk.gtk_widget_set_margin_top(@ptrCast(grid), rect.y);
    gtk.gtk_widget_set_margin_start(@ptrCast(grid), rect.x);
    const fourth = @divFloor(rect.height, 4);
    const third = @divFloor(rect.width, 3);
    inline for (0..9) |i| {
        const child = gtk.gtk_grid_get_child_at(
            grid,
            @intCast(i % 3),
            @intCast(i / 3),
        );
        switch (i) {
            3, 4, 5 => gtk.gtk_widget_set_size_request(
                child,
                third,
                fourth + fourth,
            ),
            else => gtk.gtk_widget_set_size_request(
                child,
                third,
                fourth,
            ),
        }
    }
}

fn shortcuts() void {
    inline for ([_]u8{ 'j', 'k', 'h', 'l' }) |char| {
        const action = gtk.gtk_callback_action_new(
            move_region,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger = gtk.gtk_shortcut_trigger_parse_string(
            @ptrCast(&[2]u8{ char, 0 }),
        );
        const shortcut = gtk.gtk_shortcut_new(
            trigger,
            action,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut,
        );
    }
    inline for ([_]u8{ 'q', 'r', 'u' }) |char| {
        const action = gtk.gtk_callback_action_new(switch (char) {
            'q' => quit,
            'r' => reset,
            'u' => undo,
            else => unreachable,
        }, null, null);
        const trigger = gtk.gtk_shortcut_trigger_parse_string(
            @ptrCast(&[2]u8{ char, 0 }),
        );
        const shortcut = gtk.gtk_shortcut_new(
            trigger,
            action,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut,
        );
    }
    inline for (chars) |char| {
        const action = gtk.gtk_callback_action_new(
            update_region,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger = gtk.gtk_shortcut_trigger_parse_string(
            if (char == ' ')
                "space"
            else
                @ptrCast(&[2]u8{ char, 0 }),
        );
        const shortcut = gtk.gtk_shortcut_new(
            trigger,
            action,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut,
        );
        const action_l_click = gtk.gtk_callback_action_new(
            left_click,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger_l_click = gtk.gtk_shortcut_trigger_parse_string(
            if (char == ' ')
                "<Alt>space"
            else
                @ptrCast(&[_]u8{
                    '<', 'A', 'l',
                    't', '>', char,
                    0,
                }),
        );
        const shortcut_l_click = gtk.gtk_shortcut_new(
            trigger_l_click,
            action_l_click,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut_l_click,
        );
        const action_r_click = gtk.gtk_callback_action_new(
            right_click,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger_r_click = gtk.gtk_shortcut_trigger_parse_string(
            if (char == ' ')
                "<Control>space"
            else
                @ptrCast(&[_]u8{
                    '<',  'C', 'o',
                    'n',  't', 'r',
                    'o',  'l', '>',
                    char, 0,
                }),
        );
        const shortcut_r_click = gtk.gtk_shortcut_new(
            trigger_r_click,
            action_r_click,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut_r_click,
        );
        const action_m_click = gtk.gtk_callback_action_new(
            middle_click,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger_m_click = gtk.gtk_shortcut_trigger_parse_string(
            if (char == ' ')
                "<Control><Alt>space"
            else
                @ptrCast(&[_]u8{
                    '<', 'C', 'o',
                    'n', 't', 'r',
                    'o', 'l', '>',
                    '<', 'A', 'l',
                    't', '>', char,
                    0,
                }),
        );
        const shortcut_m_click = gtk.gtk_shortcut_new(
            trigger_m_click,
            action_m_click,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut_m_click,
        );
        const action_move = gtk.gtk_callback_action_new(
            move_cursor,
            gtk.GINT_TO_POINTER(char),
            null,
        );
        const trigger_move = gtk.gtk_shortcut_trigger_parse_string(
            if (char == ' ')
                "<Shift>space"
            else
                @ptrCast(&[_]u8{ '<', 'S', 'h', 'i', 'f', 't', '>', char, 0 }),
        );
        const shortcut_move = gtk.gtk_shortcut_new(
            trigger_move,
            action_move,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut_move,
        );
    }
    for ([_]c_int{
        uinput.BTN_LEFT,
        uinput.BTN_MIDDLE,
        uinput.BTN_RIGHT,
    }) |btn| {
        const action = gtk.gtk_callback_action_new(
            cursor_click,
            gtk.GINT_TO_POINTER(btn),
            null,
        );
        const trigger =
            gtk.gtk_shortcut_trigger_parse_string(switch (btn) {
                uinput.BTN_LEFT => "semicolon",
                uinput.BTN_MIDDLE => "<Alt>semicolon",
                uinput.BTN_RIGHT => "<Control>semicolon",
                else => unreachable,
            });
        const shortcut = gtk.gtk_shortcut_new(
            trigger,
            action,
        );
        gtk.gtk_shortcut_controller_add_shortcut(
            @ptrCast(controller),
            shortcut,
        );
    }
}

fn move_region(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    user_data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    switch (gtk.GPOINTER_TO_INT(user_data)) {
        'j' => regions[index].y += 5,
        'k' => regions[index].y -= 5,
        'h' => regions[index].x -= 5,
        'l' => regions[index].x += 5,
        else => unreachable,
    }
    update_size();
    return 0;
}

fn quit(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    _: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    std.posix.system.exit(0);
    return 0;
}

fn reset(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    _: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    index = 0;
    regions[0].x = 0;
    regions[0].y = 0;
    update_size();
    return 0;
}

fn undo(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    _: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    if (index == 0) return 1;
    index -= 1;
    update_size();
    return 0;
}

fn update_region(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    user_data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    if (regions.len == index + 1) return 0;
    const rect = regions[index];
    index += 1;
    const fourth = @divFloor(rect.height, 4);
    const third = @divFloor(rect.width, 3);
    regions[index] =
        switch (gtk.GPOINTER_TO_INT(user_data)) {
            'w' => .{
                .x = rect.x,
                .y = rect.y,
                .width = third,
                .height = fourth,
            },
            's' => .{
                .x = rect.x + third,
                .y = rect.y,
                .width = third,
                .height = fourth,
            },
            'e' => .{
                .x = rect.x + 2 * third,
                .y = rect.y,
                .width = third,
                .height = fourth,
            },
            'a' => .{
                .x = rect.x,
                .y = rect.y + fourth,
                .width = third,
                .height = 2 * fourth,
            },
            ' ' => .{
                .x = rect.x + third,
                .y = rect.y + fourth,
                .width = third,
                .height = 2 * fourth,
            },
            'f' => .{
                .x = rect.x + 2 * third,
                .y = rect.y + fourth,
                .width = third,
                .height = 2 * fourth,
            },
            'i' => .{
                .x = rect.x,
                .y = rect.y + 3 * fourth,
                .width = third,
                .height = fourth,
            },
            'd' => .{
                .x = rect.x + third,
                .y = rect.y + 3 * fourth,
                .width = third,
                .height = fourth,
            },
            'o' => .{
                .x = rect.x + 2 * third,
                .y = rect.y + 3 * fourth,
                .width = third,
                .height = fourth,
            },
            else => unreachable,
        };
    update_size();
    return 0;
}

fn emit(
    fd: c_int,
    ev_type: c_ushort,
    code: c_ushort,
    val: c_int,
) void {
    _ = std.c.write(
        fd,
        @ptrCast(&uinput.input_event{
            .type = ev_type,
            .code = code,
            .value = val,
            .time = undefined,
        }),
        @sizeOf(uinput.input_event),
    );
}

fn uinput_init() c_int {
    const fd = uinput.open(
        "/dev/uinput",
        uinput.O_WRONLY | uinput.O_NONBLOCK,
    );
    if (fd < 0) {
        std.log.err("Failed to open /dev/uinput", .{});
        std.posix.system.exit(1);
    }
    _ = uinput.ioctl(fd, uinput.UI_SET_EVBIT, uinput.EV_KEY);
    var name: [80]u8 = @splat(0);
    @memcpy(name[0..8], "bullseye");
    _ = uinput.ioctl(
        fd,
        uinput.UI_DEV_SETUP,
        &uinput.uinput_setup{
            .name = name,
            .ff_effects_max = 0,
            .id = undefined,
        },
    );
    return fd;
}

fn mouse(
    region: gtk.gint,
    btn: c_ushort,
    click: bool,
) void {
    _ = gtk.gtk_widget_hide(@ptrCast(window));
    const fd = uinput_init();
    defer _ = uinput.close(fd);
    _ = uinput.ioctl(fd, uinput.UI_SET_KEYBIT, btn);
    _ = uinput.ioctl(fd, uinput.UI_SET_EVBIT, uinput.EV_ABS);
    _ = uinput.ioctl(fd, uinput.UI_SET_ABSBIT, uinput.ABS_X);
    _ = uinput.ioctl(fd, uinput.UI_SET_ABSBIT, uinput.ABS_Y);
    var abs_setup = uinput.uinput_abs_setup{
        .code = uinput.ABS_X,
        .absinfo = .{
            .minimum = 0,
            .maximum = regions[0].width - 1,
            .fuzz = 0,
            .flat = 0,
            .value = 0,
            .resolution = 0,
        },
    };
    _ = uinput.ioctl(fd, uinput.UI_ABS_SETUP, &abs_setup);
    abs_setup.code = uinput.ABS_Y;
    abs_setup.absinfo.maximum = regions[0].height - 1;
    _ = uinput.ioctl(fd, uinput.UI_ABS_SETUP, &abs_setup);
    _ = uinput.ioctl(fd, uinput.UI_DEV_CREATE);
    const sixth = @divFloor(regions[index].width, 6);
    const eighth = @divFloor(regions[index].height, 8);
    var position = [2]c_int{ regions[index].x, regions[index].y };
    switch (region) {
        'w' => {
            position[0] += sixth;
            position[1] += eighth;
        },
        's' => {
            position[0] += 3 * sixth;
            position[1] += eighth;
        },
        'e' => {
            position[0] += 5 * sixth;
            position[1] += eighth;
        },
        'a' => {
            position[0] += sixth;
            position[1] += 4 * eighth;
        },
        ' ' => {
            position[0] += 3 * sixth;
            position[1] += 4 * eighth;
        },
        'f' => {
            position[0] += 5 * sixth;
            position[1] += 4 * eighth;
        },
        'i' => {
            position[0] += sixth;
            position[1] += 7 * eighth;
        },
        'd' => {
            position[0] += 3 * sixth;
            position[1] += 7 * eighth;
        },
        'o' => {
            position[0] += 5 * sixth;
            position[1] += 7 * eighth;
        },
        else => unreachable,
    }
    var threaded = std.Io.Threaded.init_single_threaded;
    const io = threaded.io();
    std.Io.sleep(io, .fromMilliseconds(500), .awake) catch unreachable;
    while (gtk.g_main_context_iteration(gtk.g_main_context_default(), 0) == 1) {}
    emit(fd, uinput.EV_ABS, uinput.ABS_X, position[0]);
    emit(fd, uinput.EV_ABS, uinput.ABS_Y, position[1]);
    emit(fd, uinput.EV_SYN, uinput.SYN_REPORT, 0);
    if (click) {
        std.Io.sleep(io, .fromMilliseconds(100), .awake) catch unreachable;
        emit(fd, uinput.EV_KEY, btn, 1);
        emit(fd, uinput.EV_SYN, uinput.SYN_REPORT, 0);
        std.Io.sleep(io, .fromMilliseconds(100), .awake) catch unreachable;
        emit(fd, uinput.EV_KEY, btn, 0);
        emit(fd, uinput.EV_SYN, uinput.SYN_REPORT, 0);
    }
    std.Io.sleep(io, .fromMilliseconds(500), .awake) catch unreachable;
    _ = uinput.ioctl(fd, uinput.UI_DEV_DESTROY);
    std.posix.system.exit(0);
}

fn left_click(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    mouse(gtk.GPOINTER_TO_INT(data), uinput.BTN_LEFT, true);
    return 0;
}

fn right_click(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    mouse(gtk.GPOINTER_TO_INT(data), uinput.BTN_RIGHT, true);
    return 0;
}

fn middle_click(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    mouse(gtk.GPOINTER_TO_INT(data), uinput.BTN_MIDDLE, true);
    return 0;
}

fn move_cursor(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    mouse(gtk.GPOINTER_TO_INT(data), uinput.BTN_LEFT, false);
    return 0;
}

fn cursor_click(
    _: [*c]gtk.GtkWidget,
    _: ?*gtk.GVariant,
    data: gtk.gpointer,
) callconv(.c) gtk.gboolean {
    var threaded = std.Io.Threaded.init_single_threaded;
    const io = threaded.io();
    _ = gtk.gtk_widget_hide(@ptrCast(window));
    const fd = uinput_init();
    defer _ = uinput.close(fd);
    const btn: c_ushort = @intCast(gtk.GPOINTER_TO_INT(data));
    _ = uinput.ioctl(fd, uinput.UI_SET_KEYBIT, btn);
    _ = uinput.ioctl(fd, uinput.UI_DEV_CREATE);
    while (gtk.g_main_context_iteration(
        gtk.g_main_context_default(),
        0,
    ) == 1) {}
    std.Io.sleep(io, .fromMilliseconds(500), .awake) catch unreachable;
    emit(fd, uinput.EV_KEY, btn, 1);
    emit(fd, uinput.EV_SYN, uinput.SYN_REPORT, 0);
    std.Io.sleep(io, .fromMilliseconds(100), .awake) catch unreachable;
    emit(fd, uinput.EV_KEY, btn, 0);
    emit(fd, uinput.EV_SYN, uinput.SYN_REPORT, 0);
    std.Io.sleep(io, .fromMilliseconds(100), .awake) catch unreachable;
    _ = uinput.ioctl(fd, uinput.UI_DEV_DESTROY);
    std.posix.system.exit(0);
    return 0;
}
