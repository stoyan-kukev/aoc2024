const std = @import("std");

const DIRECTIONS = [4]Pos{
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = 1 },
    .{ .x = -1, .y = 0 },
    .{ .x = 0, .y = -1 },
};

const Pos = struct {
    x: isize,
    y: isize,

    fn add(self: Pos, other: Pos) Pos {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    fn eql(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

fn dfs(garden: []const []const u8, pos: Pos, char: u8, visited: *std.AutoHashMap(Pos, bool), region: *std.ArrayList(Pos)) !void {
    if (pos.x < 0 or pos.y < 0 or pos.x >= garden[0].len or pos.y >= garden.len) return;
    if (garden[@intCast(pos.y)][@intCast(pos.x)] != char) return;
    if (visited.get(pos)) |v| if (v) return;

    try visited.put(pos, true);
    try region.append(pos);

    for (DIRECTIONS) |dir| {
        try dfs(garden, pos.add(dir), char, visited, region);
    }
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len > 0) try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

fn calculateRegionPerimeter(garden: []const []const u8, region: std.ArrayList(Pos)) usize {
    var perimeter: usize = 0;

    for (region.items) |pos| {
        for (DIRECTIONS) |dir| {
            const new_pos = pos.add(dir);
            if (new_pos.x < 0 or new_pos.y < 0 or new_pos.y >= garden.len or new_pos.x >= garden[0].len or
                garden[@intCast(new_pos.y)][@intCast(new_pos.x)] != garden[@intCast(pos.y)][@intCast(pos.x)])
            {
                perimeter += 1;
            }
        }
    }

    return perimeter;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    const garden = try parseInput(allocator, input);
    defer allocator.free(garden);

    var visited = std.AutoHashMap(Pos, bool).init(allocator);
    defer visited.deinit();

    var total_price: usize = 0;

    for (garden, 0..) |row, y| {
        for (row, 0..) |char, x| {
            const pos = Pos{ .x = @intCast(x), .y = @intCast(y) };
            if (visited.get(pos) == null) {
                var region = std.ArrayList(Pos).init(allocator);
                defer region.deinit();
                try dfs(garden, pos, char, &visited, &region);

                const perimeter = calculateRegionPerimeter(garden, region);
                const area = region.items.len;
                total_price += area * perimeter;
            }
        }
    }

    std.debug.print("Final price: {}\n", .{total_price});
}
