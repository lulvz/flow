const std = @import("std");
const Allocator = std.mem.Allocator;
const tp = @import("thespian");
const Buffer = @import("Buffer");

const Plane = @import("renderer").Plane;
const command = @import("command");
const EventHandler = @import("EventHandler");

const Widget = @import("../Widget.zig");
const Button = @import("../Button.zig");

const utf8_sanitized_warning = "  UTF";

line: usize = 0,
lines: usize = 0,
column: usize = 0,
buf: [256]u8 = undefined,
rendered: [:0]const u8 = "",
eol_mode: Buffer.EolMode = .lf,
utf8_sanitized: bool = false,

const Self = @This();

pub fn create(allocator: Allocator, parent: Plane, event_handler: ?EventHandler) @import("widget.zig").CreateError!Widget {
    return Button.create_widget(Self, allocator, parent, .{
        .ctx = .{},
        .label = "",
        .on_click = on_click,
        .on_layout = layout,
        .on_render = render,
        .on_receive = receive,
        .on_event = event_handler,
    });
}

fn on_click(_: *Self, _: *Button.State(Self)) void {
    command.executeName("goto", .{}) catch {};
}

pub fn layout(self: *Self, btn: *Button.State(Self)) Widget.Layout {
    const warn_len = if (self.utf8_sanitized) btn.plane.egc_chunk_width(utf8_sanitized_warning, 0, 1) else 0;
    const len = btn.plane.egc_chunk_width(self.rendered, 0, 1) + warn_len;
    return .{ .static = len };
}

pub fn render(self: *Self, btn: *Button.State(Self), theme: *const Widget.Theme) bool {
    btn.plane.set_base_style(theme.editor);
    btn.plane.erase();
    btn.plane.home();
    btn.plane.set_style(if (btn.active) theme.editor_cursor else if (btn.hover) theme.statusbar_hover else theme.statusbar);
    btn.plane.fill(" ");
    btn.plane.home();
    if (self.utf8_sanitized) {
        btn.plane.set_style(.{ .fg = theme.editor_error.fg.? });
        _ = btn.plane.putstr(utf8_sanitized_warning) catch {};
    }
    btn.plane.set_style(if (btn.active) theme.editor_cursor else if (btn.hover) theme.statusbar_hover else theme.statusbar);
    _ = btn.plane.putstr(self.rendered) catch {};
    return false;
}

fn format(self: *Self) void {
    var fbs = std.io.fixedBufferStream(&self.buf);
    const writer = fbs.writer();
    const eol_mode = switch (self.eol_mode) {
        .lf => "",
        .crlf => " [␍␊]",
    };
    std.fmt.format(writer, "{s} Ln {d}, Col {d} ", .{ eol_mode, self.line + 1, self.column + 1 }) catch {};
    self.rendered = @ptrCast(fbs.getWritten());
    self.buf[self.rendered.len] = 0;
}

pub fn receive(self: *Self, _: *Button.State(Self), _: tp.pid_ref, m: tp.message) error{Exit}!bool {
    var eol_mode: Buffer.EolModeTag = @intFromEnum(Buffer.EolMode.lf);
    if (try m.match(.{ "E", "pos", tp.extract(&self.lines), tp.extract(&self.line), tp.extract(&self.column) })) {
        self.format();
    } else if (try m.match(.{ "E", "eol_mode", tp.extract(&eol_mode), tp.extract(&self.utf8_sanitized) })) {
        self.eol_mode = @enumFromInt(eol_mode);
        self.format();
    } else if (try m.match(.{ "E", "open", tp.more })) {
        self.eol_mode = .lf;
    } else if (try m.match(.{ "E", "close" })) {
        self.lines = 0;
        self.line = 0;
        self.column = 0;
        self.rendered = "";
        self.eol_mode = .lf;
        self.utf8_sanitized = false;
    }
    return false;
}
