const std = @import("std");

const Pos = struct {
    x: isize,
    y: isize,

    fn distance(self: Pos, other: Pos) f64 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return @sqrt(@as(f64, @floatFromInt(dx * dx + dy * dy)));
    }

    pub fn hash(self: Pos) u64 {
        return @as(u64, @intCast(self.x)) * 31 + @as(u64, @intCast(self.y));
    }

    pub fn eql(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const AntennaMap = std.AutoHashMap(u8, std.ArrayList(Pos));

fn isValidAntinode(node: Pos, map: [][]const u8) bool {
    return node.x >= 0 and node.y >= 0 and
        @as(usize, @intCast(node.x)) < map[0].len and
        @as(usize, @intCast(node.y)) < map.len;
}

fn findAntennas(allocator: std.mem.Allocator, map: [][]const u8) !AntennaMap {
    var output = AntennaMap.init(allocator);
    for (map, 0..) |row, j| {
        for (row, 0..) |cell, i| {
            const isDigit = cell >= '0' and cell <= '9';
            const isLowerLetter = cell >= 'a' and cell <= 'z';
            const isUpperLetter = cell >= 'A' and cell <= 'Z';
            if (isDigit or isLowerLetter or isUpperLetter) {
                if (output.getPtr(cell)) |entry| {
                    try entry.append(.{ .x = @intCast(i), .y = @intCast(j) });
                } else {
                    var list = std.ArrayList(Pos).init(allocator);
                    try list.append(.{ .x = @intCast(i), .y = @intCast(j) });
                    try output.put(cell, list);
                }
            }
        }
    }
    return output;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var output = std.ArrayList([]const u8).init(allocator);
    defer output.deinit();
    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len > 0) {
            try output.append(try allocator.dupe(u8, line));
        }
    }
    return try output.toOwnedSlice();
}

fn calculateAntinode(pos1: Pos, pos2: Pos, i: isize) Pos {
    return .{
        .x = pos1.x + i * (pos2.x - pos1.x),
        .y = pos1.y + i * (pos2.y - pos1.y),
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    const map = try parseInput(allocator, input);
    defer {
        for (map) |row| {
            allocator.free(row);
        }
        allocator.free(map);
    }

    var antenna_map = try findAntennas(allocator, map);
    defer {
        var iter = antenna_map.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        antenna_map.deinit();
    }

    var antinode_positions = std.AutoHashMap(Pos, void).init(allocator);
    defer antinode_positions.deinit();

    var freq_iter = antenna_map.iterator();
    while (freq_iter.next()) |freq_entry| {
        const positions = freq_entry.value_ptr.*;

        for (0..positions.items.len) |i| {
            for (i + 1..positions.items.len) |j| {
                const ant_pos1 = positions.items[i];
                const ant_pos2 = positions.items[j];

                var k: isize = 1;
                var l: isize = 1;

                // Calculate forward and backward antinodes
                var possible_node1 = calculateAntinode(ant_pos1, ant_pos2, k);
                var possible_node2 = calculateAntinode(ant_pos2, ant_pos1, l);

                while (isValidAntinode(possible_node1, map)) : (k += 1) {
                    try antinode_positions.put(possible_node1, {});
                    possible_node1 = calculateAntinode(ant_pos1, ant_pos2, k);
                }

                while (isValidAntinode(possible_node2, map)) : (l += 1) {
                    try antinode_positions.put(possible_node2, {});
                    possible_node2 = calculateAntinode(ant_pos2, ant_pos1, l);
                }
            }
        }
    }

    // Print the count of unique antinode positions
    std.debug.print("Number of unique antinode positions: {}\n", .{antinode_positions.count()});
}
