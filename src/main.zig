const std = @import("std");
const print = std.debug.print;

// ANSI color codes
const green = "\x1b[32m";
const red = "\x1b[31m";
const yellow = "\x1b[33m";
const reset = "\x1b[0m";

pub fn centerText(comptime text: []const u8, comptime tree_height: usize) !void {
    const writer = std.io.getStdOut().writer();
    const tree_width = 2 * tree_height - 1;
    const padding = (tree_width - text.len) / 2;
    try writer.writeAll(" " ** padding);
    try writer.writeAll(text);
    try writer.writeByte('\n');
}

pub fn printChristmasTree(comptime height: usize) !void {
    const writer = std.io.getStdOut().writer();

    try writer.writeAll(" " ** (height - 1));
    try writer.print("{s}★{s}\n", .{ yellow, reset });

    comptime var row: usize = 0;
    inline while (row < height) : (row += 1) {
        const spaces = height - row - 1;
        try writer.writeAll(" " ** spaces);

        var col: usize = 0;
        while (col < (2 * row + 1)) : (col += 1) {
            const random = std.crypto.random;
            const decoration_chance = random.boolean();

            if (decoration_chance and col % 2 == 1) {
                try writer.print("{s}o{s}", .{ red, reset });
            } else {
                try writer.print("{s}*{s}", .{ green, reset });
            }
        }
        try writer.writeByte('\n');
    }

    const trunk_height = @max(height / 4, 1);
    comptime var i: usize = 0;
    inline while (i < trunk_height) : (i += 1) {
        try writer.writeAll(" " ** (height - 2));
        try writer.print("{s}||{s}\n", .{ "\x1b[33m", reset });
    }
}

pub fn main() !void {
    const height = 15;
    try printChristmasTree(height);
    try centerText(red ++ "Merry Christmas!" ++ reset, height + red.len);
    try centerText("(The last star is a freebie)", height);
}
