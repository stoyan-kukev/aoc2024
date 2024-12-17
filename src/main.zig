const std = @import("std");

const DIRECTIONS = [4]Pos{
    .{ .x = 0, .y = -1 },
    .{ .x = 0, .y = 1 },
    .{ .x = -1, .y = 0 },
    .{ .x = 1, .y = 0 },
};

const PosContext = struct {
    pub fn hash(self: @This(), key: Pos) u64 {
        _ = self;
        const x_bits: u32 = @bitCast(key.x);
        const y_bits: u32 = @bitCast(key.y);
        return (@as(u64, x_bits) << 32) | y_bits;
    }

    pub fn eql(self: @This(), a: Pos, b: Pos) bool {
        _ = self;
        return a.x == b.x and a.y == b.y;
    }
};

const Pos = struct {
    x: f32,
    y: f32,

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

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len > 0) try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

fn findRegions(allocator: std.mem.Allocator, grid: []const []const u8) ![]std.ArrayList(Pos) {
    var regions = std.ArrayList(std.ArrayList(Pos)).init(allocator);
    defer regions.deinit();

    var visited = std.HashMap(Pos, void, PosContext, 80).init(allocator);
    defer visited.deinit();

    for (grid, 0..) |row, y| {
        for (row, 0..) |_, x| {
            const pos = Pos{ .x = @floatFromInt(x), .y = @floatFromInt(y) };

            if (!visited.contains(pos)) {
                var region = std.ArrayList(Pos).init(allocator);
                try findRegion(grid, pos, &visited, &region);
                try regions.append(region);
            }
        }
    }

    return try regions.toOwnedSlice();
}

fn findRegion(grid: []const []const u8, start_pos: Pos, visited: *std.HashMap(Pos, void, PosContext, 80), region: *std.ArrayList(Pos)) !void {
    var queue = std.ArrayList(Pos).init(std.heap.page_allocator);
    defer queue.deinit();

    try queue.append(start_pos);
    try visited.put(start_pos, {});
    try region.append(start_pos);

    const crop = grid[@intFromFloat(start_pos.y)][@intFromFloat(start_pos.x)];

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);

        for (DIRECTIONS) |dir| {
            const next_pos = current.add(dir);

            if (next_pos.y < 0 or next_pos.x < 0 or
                next_pos.y >= @as(f32, @floatFromInt(grid.len)) or next_pos.x >= @as(f32, @floatFromInt(grid[0].len))) continue;

            if (grid[@intFromFloat(next_pos.y)][@intFromFloat(next_pos.x)] != crop) continue;
            if (visited.contains(next_pos)) continue;

            try visited.put(next_pos, {});
            try region.append(next_pos);
            try queue.append(next_pos);
        }
    }
}

fn calculateSides(region: std.ArrayList(Pos)) usize {
    var corner_candidates = std.HashMap(Pos, void, PosContext, 80).init(std.heap.page_allocator);
    defer corner_candidates.deinit();

    for (region.items) |pos| {
        const corners = [4]Pos{
            .{ .x = pos.x - 0.5, .y = pos.y - 0.5 },
            .{ .x = pos.x + 0.5, .y = pos.y - 0.5 },
            .{ .x = pos.x + 0.5, .y = pos.y + 0.5 },
            .{ .x = pos.x - 0.5, .y = pos.y + 0.5 },
        };

        for (corners) |corner| {
            _ = corner_candidates.put(corner, {}) catch {};
        }
    }

    var corners: usize = 0;
    var corner_iter = corner_candidates.keyIterator();
    while (corner_iter.next()) |corner| {
        const config = [4]bool{
            isInRegion(region, .{ .x = corner.x - 0.5, .y = corner.y - 0.5 }),
            isInRegion(region, .{ .x = corner.x + 0.5, .y = corner.y - 0.5 }),
            isInRegion(region, .{ .x = corner.x + 0.5, .y = corner.y + 0.5 }),
            isInRegion(region, .{ .x = corner.x - 0.5, .y = corner.y + 0.5 }),
        };

        const num_true = countTrue(&config);

        if (num_true == 1) {
            corners += 1;
        } else if (num_true == 2) {
            if ((config[0] and config[2]) or (config[1] and config[3])) {
                corners += 2;
            }
        } else if (num_true == 3) {
            corners += 1;
        }
    }

    return corners;
}

fn isInRegion(region: std.ArrayList(Pos), pos: Pos) bool {
    for (region.items) |r_pos| {
        if (r_pos.x == pos.x and r_pos.y == pos.y) return true;
    }
    return false;
}

fn countTrue(arr: []const bool) usize {
    var count: usize = 0;
    for (arr) |val| {
        if (val) count += 1;
    }
    return count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    const grid = try parseInput(allocator, input);
    defer allocator.free(grid);

    const regions = try findRegions(allocator, grid);
    defer {
        for (regions) |region| {
            region.deinit();
        }
        allocator.free(regions);
    }

    var total: usize = 0;
    for (regions) |region| {
        total += region.items.len * calculateSides(region);
    }

    std.debug.print("Result: {}\n", .{total});
}
