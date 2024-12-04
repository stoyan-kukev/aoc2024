const std = @import("std");
const input = @embedFile("input.txt");

const Direction = enum {
    Horizontal,
    Vertical,
    DiagonalLeft,
    DiagonalRight,
};

fn splitStringToGrid(allocator: std.mem.Allocator, string: []const u8) ![][]const u8 {
    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();

    var lines = std.mem.splitSequence(u8, string, "\n");

    while (lines.next()) |line| {
        if (line.len > 0) {
            try result.append(line);
        }
    }

    return result.toOwnedSlice();
}

fn checkSequenceFromPoint(
    grid: [][]const u8,
    sequence: []const u8,
    start_row: usize,
    start_col: usize,
    direction: Direction,
    reverse: bool,
) bool {
    const height = grid.len;
    const width = grid[0].len;

    const row_step: i2 = switch (direction) {
        .Horizontal => 0,
        else => 1,
    };

    const col_step: i2 = switch (direction) {
        .Horizontal => 1,
        .Vertical => 0,
        .DiagonalRight => 1,
        .DiagonalLeft => -1,
    };

    const sign: i2 = if (reverse) -1 else 1;

    const last_row = @as(i32, @intCast(start_row)) + sign * @as(i32, @intCast(row_step)) * @as(i32, @intCast(sequence.len - 1));
    const last_col = @as(i32, @intCast(start_col)) + sign * @as(i32, @intCast(col_step)) * @as(i32, @intCast(sequence.len - 1));

    if (last_row < 0 or last_row >= @as(i32, @intCast(height)) or
        last_col < 0 or last_col >= @as(i32, @intCast(width)))
    {
        return false;
    }

    for (0..sequence.len) |i| {
        const check_row = @as(usize, @intCast(@as(i32, @intCast(start_row)) + sign * @as(i32, @intCast(row_step)) * @as(i32, @intCast(i))));
        const check_col = @as(usize, @intCast(@as(i32, @intCast(start_col)) + sign * @as(i32, @intCast(col_step)) * @as(i32, @intCast(i))));
        if (grid[check_row][check_col] != sequence[i]) {
            return false;
        }
    }

    return true;
}

fn checkDirection(
    grid: [][]const u8,
    sequence: []const u8,
    direction: Direction,
    reverse: bool,
) u32 {
    const height = grid.len;
    const width = grid[0].len;

    var count: u32 = 0;
    for (0..height) |row| {
        for (0..width) |col| {
            if (checkSequenceFromPoint(grid, sequence, row, col, direction, reverse)) {
                count += 1;
            }
        }
    }

    return count;
}

fn findSequenceCount(grid: [][]const u8, sequence: []const u8) u32 {
    const directions = [_]Direction{
        .Horizontal,
        .Vertical,
        .DiagonalLeft,
        .DiagonalRight,
    };

    var count: u32 = 0;
    for (directions) |direction| {
        count += checkDirection(grid, sequence, direction, false);
        count += checkDirection(grid, sequence, direction, true);
    }

    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try splitStringToGrid(allocator, input);
    defer allocator.free(grid);

    const count = findSequenceCount(grid, "XMAS");
    std.debug.print("XMAS spotted {} times\n", .{count});
}
