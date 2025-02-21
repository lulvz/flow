const builtin = @import("builtin");

frame_rate: usize = 60,
theme: []const u8 = "default",
input_mode: []const u8 = "flow",
gutter_line_numbers_mode: ?LineNumberMode = null,
gutter_line_numbers_style: DigitStyle = .ascii,
gutter_symbols: bool = true,
enable_terminal_cursor: bool = true,
enable_terminal_color_scheme: bool = builtin.os.tag != .windows,
highlight_current_line: bool = true,
highlight_current_line_gutter: bool = true,
whitespace_mode: []const u8 = "none",
inline_diagnostics: bool = true,
animation_min_lag: usize = 0, //milliseconds
animation_max_lag: usize = 150, //milliseconds
enable_format_on_save: bool = false,
default_cursor: []const u8 = "default",

indent_size: usize = 4,
tab_width: usize = 8,

top_bar: []const u8 = "tabs",
bottom_bar: []const u8 = "mode file log selection diagnostics keybind linenumber clock spacer",

lsp_request_timeout: usize = 10,

include_files: []const u8 = "",

pub const DigitStyle = enum {
    ascii,
    digital,
    subscript,
    superscript,
};

pub const LineNumberMode = enum {
    none,
    relative,
    absolute,
};
