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

fn getVisitedForTrailhead(allocator: std.mem.Allocator, start_pos: Pos, map: [][]u32) !usize {
    var paths = std.ArrayList(std.ArrayList(Pos)).init(allocator);
    defer {
        for (paths.items) |*path| {
            path.deinit();
        }
        paths.deinit();
    }

    var initial_path = std.ArrayList(Pos).init(allocator);
    try initial_path.append(start_pos);
    try paths.append(initial_path);

    var result_paths: usize = 0;

    while (paths.items.len > 0) {
        var current_path = paths.orderedRemove(0);
        defer current_path.deinit();
        const current_pos = current_path.items[current_path.items.len - 1];
        const current_height = map[@intCast(current_pos.y)][@intCast(current_pos.x)];

        if (current_height == 9) {
            result_paths += 1;
            continue;
        }

        for (DIRECTIONS) |dir| {
            const new_pos = current_pos.add(dir);
            if (!validPos(new_pos, map)) continue;

            const new_height = map[@intCast(new_pos.y)][@intCast(new_pos.x)];
            if (new_height == current_height + 1) {
                var new_path = try std.ArrayList(Pos).initCapacity(allocator, current_path.items.len + 1);
                new_path.appendSliceAssumeCapacity(current_path.items);
                try new_path.append(new_pos);
                try paths.append(new_path);
            }
        }
    }

    return result_paths;
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
        const visited = try getVisitedForTrailhead(allocator, trailhead.*, map.items);

        sum += visited;
    }

    std.debug.print("Total: {}\n", .{sum});
}
