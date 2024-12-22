const std = @import("std");
const print = std.debug.print;

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var output = std.ArrayList([]u8).init(allocator);

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len < 1) continue;

        try output.append(try allocator.dupe(u8, line));
    }

    return try output.toOwnedSlice();
}

const Pos = struct {
    row: isize,
    col: isize,
};

const State = struct {
    pos: Pos,
    steps: isize,
};

const DIRECTIONS = [4]Pos{
    .{ .row = 0, .col = 1 },
    .{ .row = 0, .col = -1 },
    .{ .row = 1, .col = 0 },
    .{ .row = -1, .col = 0 },
};

fn generateDists(allocator: std.mem.Allocator, grid: [][]u8, start_pos: Pos) !std.AutoHashMap(Pos, isize) {
    var output = std.AutoHashMap(Pos, isize).init(allocator);

    var queue = std.ArrayList(State).init(allocator);
    defer queue.deinit();

    try queue.append(.{ .pos = start_pos, .steps = 0 });

    while (queue.items.len > 0) {
        const state = queue.orderedRemove(0);

        if (output.get(state.pos) != null) {
            continue;
        }

        try output.put(state.pos, state.steps);
        for (DIRECTIONS) |dir| {
            const new_row = state.pos.row + dir.row;
            const new_col = state.pos.col + dir.col;

            if (grid[@intCast(new_col)][@intCast(new_row)] != '#') {
                try queue.append(.{ .pos = .{ .row = new_row, .col = new_col }, .steps = state.steps + 1 });
            }
        }
    }

    return output;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    const grid = try parseInput(allocator, input);
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
        allocator.free(grid);
    }

    const start_pos: Pos = blk: {
        for (grid, 0..) |row, y| {
            for (row, 0..) |char, x| {
                if (char == 'S') {
                    break :blk .{ .row = @intCast(x), .col = @intCast(y) };
                }
            }
        }

        unreachable;
    };

    var dists = try generateDists(allocator, grid, start_pos);
    defer dists.deinit();

    var shortcuts = std.AutoHashMap(isize, usize).init(allocator);
    defer shortcuts.deinit();

    const allowed_timeskip = 20;
    const target_time_to_save = 100;

    for (0..grid.len) |col| {
        for (0..grid[0].len) |row| {
            const curr_pos = Pos{ .row = @intCast(row), .col = @intCast(col) };
            const curr_steps = dists.get(curr_pos);
            if (curr_steps == null) continue;

            for (2..allowed_timeskip + 1) |len_cheat| {
                for (0..len_cheat + 1) |dr| {
                    const dc: isize = @intCast(len_cheat - dr);

                    var new_positions = std.AutoHashMap(Pos, void).init(allocator);
                    defer new_positions.deinit();

                    const r: isize = @intCast(row);
                    const c: isize = @intCast(col);
                    const dr_i: isize = @intCast(dr);

                    try new_positions.put(.{ .row = r + dr_i, .col = c + dc }, {});
                    try new_positions.put(.{ .row = r + dr_i, .col = c - dc }, {});
                    try new_positions.put(.{ .row = r - dr_i, .col = c + dc }, {});
                    try new_positions.put(.{ .row = r - dr_i, .col = c - dc }, {});

                    var iter = new_positions.keyIterator();
                    while (iter.next()) |new_pos| {
                        const new_steps = dists.get(new_pos.*);
                        if (new_steps == null) continue;

                        const time_saved = new_steps.? - curr_steps.? - @as(isize, @intCast(len_cheat));
                        if (time_saved >= target_time_to_save) {
                            if (shortcuts.get(time_saved)) |prev_count| {
                                try shortcuts.put(time_saved, prev_count + 1);
                            } else {
                                try shortcuts.put(time_saved, 1);
                            }
                        }
                    }
                }
            }
        }
    }

    var sum: usize = 0;
    var iter = shortcuts.iterator();
    while (iter.next()) |entry| {
        sum += entry.value_ptr.*;
    }

    print("Cheats that save above {} for {} timeskip -> {}\n", .{ target_time_to_save, allowed_timeskip, sum });
}
