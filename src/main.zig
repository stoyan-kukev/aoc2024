const std = @import("std");

const input = @embedFile("input.txt");

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

fn countXMASPatterns(grid: [][]const u8) u32 {
    const height = grid.len;
    const width = grid[0].len;

    var count: u32 = 0;

    for (1..height - 1) |row| {
        for (1..width - 1) |col| {
            // Check center
            if (grid[row][col] != 'A') continue;

            // Check all combinations for both diagonals
            const diagonal1 = checkDiagonal(grid, row, col, -1, -1, 1, 1);
            const diagonal2 = checkDiagonal(grid, row, col, -1, 1, 1, -1);

            if (diagonal1 and diagonal2) count += 1;
        }
    }

    return count;
}

fn checkDiagonal(grid: [][]const u8, row: usize, col: usize, dx1: isize, dy1: isize, dx2: isize, dy2: isize) bool {
    const height = grid.len;
    const width = grid[0].len;

    // Calculate first diagonal arm position
    const x1 = @as(isize, @intCast(row)) + dx1;
    const y1 = @as(isize, @intCast(col)) + dy1;

    // Calculate second diagonal arm position
    const x2 = @as(isize, @intCast(row)) + dx2;
    const y2 = @as(isize, @intCast(col)) + dy2;

    // Ensure indices are within bounds
    if (x1 < 0 or x1 >= @as(isize, @intCast(height))) return false;
    if (y1 < 0 or y1 >= @as(isize, @intCast(width))) return false;
    if (x2 < 0 or x2 >= @as(isize, @intCast(height))) return false;
    if (y2 < 0 or y2 >= @as(isize, @intCast(width))) return false;

    // Retrieve values at diagonal positions
    const first = grid[@as(usize, @intCast(x1))][@as(usize, @intCast(y1))];
    const last = grid[@as(usize, @intCast(x2))][@as(usize, @intCast(y2))];

    // Valid if it forms either MAS or SAM
    return (first == 'M' and last == 'S') or (first == 'S' and last == 'M');
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try splitStringToGrid(allocator, input);
    defer allocator.free(grid);

    const count = countXMASPatterns(grid);
    std.debug.print("X-MAS patterns spotted: {}\n", .{count});
}
