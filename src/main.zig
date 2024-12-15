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
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([]u32) {
    var output = std.ArrayList([]u32).init(allocator);
    errdefer output.deinit();

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        var row = std.ArrayList(u32).init(allocator);
        errdefer row.deinit();

        for (line) |char| {
            if (line.len < 1 or !std.ascii.isDigit(char)) continue;
            try row.append(try std.fmt.parseInt(u32, &.{char}, 10));
        }

        try output.append(try row.toOwnedSlice());
    }

    return output;
}

fn printMap(map: [][]u32) void {
    for (map) |row| {
        for (row) |height| {
            std.debug.print("{}", .{height});
        }
        std.debug.print("\n", .{});
    }
}

fn findTrailheads(allocator: std.mem.Allocator, map: [][]u32) !std.AutoHashMap(Pos, void) {
    var output = std.AutoHashMap(Pos, void).init(allocator);

    for (map, 0..) |row, y| {
        for (row, 0..) |_, x| {
            if (map[y][x] == 0) {
                try output.put(.{ .x = @intCast(x), .y = @intCast(y) }, {});
            }
        }
    }

    return output;
}

fn validPos(pos: Pos, map: [][]u32) bool {
    return pos.x >= 0 and
        pos.x < map[0].len and
        pos.y >= 0 and
        pos.y < map.len - 1;
}

fn getVisitedForTrailhead(allocator: std.mem.Allocator, start_pos: Pos, map: [][]u32, debug: bool) !usize {
    var visited = std.AutoHashMap(Pos, void).init(allocator);
    defer visited.deinit();

    var queue = std.ArrayList(Pos).init(allocator);
    defer queue.deinit();

    try queue.append(start_pos);
    try visited.put(start_pos, {});

    while (queue.items.len > 0) {
        var current_cell = queue.orderedRemove(0);
        const old_val = map[@intCast(current_cell.y)][@intCast(current_cell.x)];

        if (debug) std.debug.print("Currently on ({}, {})\n", .{ current_cell.x, current_cell.y });

        for (DIRECTIONS) |dir| {
            const new_pos = current_cell.add(dir);
            if (debug) std.debug.print("Attempting ({}, {}) ...\n", .{ new_pos.x, new_pos.y });
            if (!validPos(new_pos, map) or visited.get(new_pos) != null) continue;

            const cur_val = map[@intCast(new_pos.y)][@intCast(new_pos.x)];

            const is_uphill = cur_val == old_val + 1;
            if (is_uphill) {
                if (debug) std.debug.print("Moving from ({}, {}) to ({}, {})\n", .{ current_cell.x, current_cell.y, new_pos.x, new_pos.y });
                try queue.append(new_pos);
                try visited.put(new_pos, {});
            }
        }
    }

    var peaks_reached: usize = 0;
    var iter = visited.keyIterator();
    while (iter.next()) |pos| {
        if (map[@intCast(pos.y)][@intCast(pos.x)] == 9) {
            peaks_reached += 1;
        }
    }

    return peaks_reached;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    const map = try parseInput(allocator, input);
    defer {
        for (map.items) |row| {
            allocator.free(row);
        }
        map.deinit();
    }

    var trailheads = try findTrailheads(allocator, map.items);
    defer trailheads.deinit();

    var sum: usize = 0;

    var iter = trailheads.keyIterator();
    while (iter.next()) |trailhead| {
        const visited = try getVisitedForTrailhead(allocator, trailhead.*, map.items, false);

        sum += visited;
    }

    std.debug.print("Total: {}\n", .{sum});
}
