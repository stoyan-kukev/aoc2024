const std = @import("std");
const print = std.debug.print;

const Vec = struct {
    x: isize,
    y: isize,

    fn add(self: Vec, other: Vec) Vec {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};

var dir_map = std.StaticStringMap(Vec).initComptime(&.{
    .{ "^", .{ .x = 0, .y = -1 } },
    .{ ">", .{ .x = 1, .y = 0 } },
    .{ "v", .{ .x = 0, .y = 1 } },
    .{ "<", .{ .x = -1, .y = 0 } },
});

const Map = std.ArrayList([]u8);
const Moves = std.ArrayList(Vec);

const ParsedInput = struct {
    map: Map,
    moves: Moves,
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !ParsedInput {
    var section_split = std.mem.splitSequence(u8, input, "\n\n");
    const map_section = section_split.next().?;
    const moves_section = section_split.next().?;

    var map = Map.init(allocator);
    errdefer {
        for (map.items) |row| {
            allocator.free(row);
        }
        map.deinit();
    }

    var map_iter = std.mem.splitSequence(u8, map_section, "\n");
    while (map_iter.next()) |row| {
        if (row.len < 1) continue;

        try map.append(try allocator.dupe(u8, row));
    }

    var moves = Moves.init(allocator);
    errdefer moves.deinit();

    for (moves_section) |char| {
        if (char == '\n') continue;

        try moves.append(dir_map.get(&.{char}) orelse return error.What);
    }

    return .{
        .map = map,
        .moves = moves,
    };
}

fn moveBox(map: *Map, pos: Vec, dir: Vec) bool {
    const new_pos = pos.add(dir);

    if (new_pos.x > map.items[0].len or new_pos.y > map.items.len) {
        return false;
    }

    if (map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] == '#') {
        return false;
    }

    var can_move = true;

    if (map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] == 'O') {
        can_move = moveBox(map, new_pos, dir);
    }

    if (can_move) {
        map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] = 'O';
        map.items[@intCast(pos.y)][@intCast(pos.x)] = '.';

        return true;
    }

    return false;
}

fn moveRobot(map: *Map, pos: *Vec, dir: Vec) void {
    const new_pos = pos.add(dir);

    if (new_pos.x > map.items[0].len or new_pos.y > map.items.len) {
        return;
    }

    if (map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] == '#') {
        return;
    }

    var can_move = true;

    if (map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] == 'O') {
        can_move = moveBox(map, new_pos, dir);
    }

    if (can_move) {
        map.items[@intCast(new_pos.y)][@intCast(new_pos.x)] = '@';
        map.items[@intCast(pos.y)][@intCast(pos.x)] = '.';
        pos.* = new_pos;
    }
}

fn printMap(map: *Map) void {
    for (map.items) |row| {
        for (row) |cell| {
            print("{c}", .{cell});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = @embedFile("input.txt");
    var parsed_input = try parseInput(allocator, input);
    defer {
        parsed_input.moves.deinit();
        for (parsed_input.map.items) |row| {
            allocator.free(row);
        }
        parsed_input.map.deinit();
    }

    var robot_pos: Vec = blk: {
        for (parsed_input.map.items, 0..) |row, y| {
            for (row, 0..) |_, x| {
                if (parsed_input.map.items[y][x] == '@') {
                    break :blk .{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    };
                }
            }
        }
    };

    while (parsed_input.moves.items.len > 0) {
        const dir = parsed_input.moves.orderedRemove(0);
        moveRobot(&parsed_input.map, &robot_pos, dir);
    }

    var sum: usize = 0;

    for (parsed_input.map.items, 0..) |row, y| {
        for (row, 0..) |_, x| {
            if (parsed_input.map.items[y][x] == 'O') {
                sum += 100 * y + x;
            }
        }
    }

    print("Sum: {}\n", .{sum});
}
