const std = @import("std");

const Pos = struct {
    x: usize,
    y: usize,

    fn addDir(self: *Pos, dir: Dir) !void {
        const curr_x: isize = @intCast(self.x);
        const curr_y: isize = @intCast(self.y);

        if (curr_x + dir.x < 0 or curr_y + dir.y < 0) {
            return error.Underflow;
        }

        const new_x: usize = @intCast(curr_x + dir.x);
        const new_y: usize = @intCast(curr_y + dir.y);

        self.x = new_x;
        self.y = new_y;
    }

    fn newFromSelf(self: Pos) Pos {
        return .{
            .x = self.x,
            .y = self.y,
        };
    }
};

const Dir = struct {
    x: isize,
    y: isize,
};

fn generateMapFromInput(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var output = std.ArrayList([]u8).init(allocator);

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len < 1) continue;

        var chars = std.ArrayList(u8).init(allocator);
        for (line) |char| {
            try chars.append(char);
        }

        try output.append(try chars.toOwnedSlice());
    }

    return try output.toOwnedSlice();
}

fn findGuardPos(map: [][]u8) !Pos {
    for (map, 0..) |row, y| {
        for (row, 0..) |_, x| {
            switch (map[y][x]) {
                '<', '>', '^', 'v' => return .{ .x = x, .y = y },
                else => continue,
            }
        }
    }

    return error.NoGuardFound;
}

fn getGuardDirection(map: [][]u8, guard_pos: Pos) !Dir {
    return switch (map[guard_pos.y][guard_pos.x]) {
        '>' => .{ .x = 1, .y = 0 },
        '<' => .{ .x = -1, .y = 0 },
        '^' => .{ .x = 0, .y = -1 },
        'v' => .{ .x = 0, .y = 1 },
        else => error.InvalidCharForDirection,
    };
}

fn getNewGuardRotation(current_rotation: u8) u8 {
    return switch (current_rotation) {
        '^' => '>',
        '>' => 'v',
        'v' => '<',
        '<' => '^',
        else => unreachable,
    };
}

fn countGuardSteps(allocator: std.mem.Allocator, map: [][]u8, guard_pos: *Pos) !usize {
    var visited_pos = std.AutoArrayHashMap(Pos, void).init(allocator);
    defer visited_pos.deinit();

    while (true) {
        const current_guard = map[guard_pos.y][guard_pos.x];
        const guard_dir = try getGuardDirection(map, guard_pos.*);

        var new_guard_pos = guard_pos.newFromSelf();
        new_guard_pos.addDir(guard_dir) catch {
            return visited_pos.count();
        };

        if (new_guard_pos.x >= map[0].len or new_guard_pos.y >= map.len) {
            return visited_pos.count();
        }

        switch (map[new_guard_pos.y][new_guard_pos.x]) {
            '#' => {
                map[guard_pos.y][guard_pos.x] = getNewGuardRotation(current_guard);
            },
            '.' => {
                map[new_guard_pos.y][new_guard_pos.x] = current_guard;
                map[guard_pos.y][guard_pos.x] = '.';

                guard_pos.x = new_guard_pos.x;
                guard_pos.y = new_guard_pos.y;

                try visited_pos.put(.{ .x = guard_pos.x, .y = guard_pos.y }, {});
            },
            else => unreachable,
        }
    }
}

fn printMap(map: [][]u8) void {
    for (map) |row| {
        for (row) |item| {
            std.debug.print("{c}", .{item});
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    const map = try generateMapFromInput(allocator, input);
    defer {
        for (map) |row| {
            allocator.free(row);
        }
        allocator.free(map);
    }

    var guard_pos = try findGuardPos(map);

    const steps = try countGuardSteps(allocator, map, &guard_pos);
    std.debug.print("Steps: {}\n", .{steps});
}
