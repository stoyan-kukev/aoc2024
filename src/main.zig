const std = @import("std");
const print = std.debug.print;

const width = 71;
const height = 71;

const Pos = struct {
    row: isize,
    col: isize,
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Pos) {
    var output = std.ArrayList(Pos).init(allocator);

    var input_iter = std.mem.splitSequence(u8, input, "\n");
    while (input_iter.next()) |line| {
        if (line.len < 1) continue;

        var num_iter = std.mem.splitSequence(u8, line, ",");
        const row = try std.fmt.parseInt(isize, num_iter.next().?, 10);
        const col = try std.fmt.parseInt(isize, num_iter.next().?, 10);

        try output.append(.{ .row = row, .col = col });
    }

    return output;
}

const DIRECTIONS = [4]Pos{
    .{ .row = 1, .col = 0 },
    .{ .row = 0, .col = 1 },
    .{ .row = -1, .col = 0 },
    .{ .row = 0, .col = -1 },
};

const State = struct {
    pos: Pos,
    steps: usize,
};

fn findPath(allocator: std.mem.Allocator, blocks: []Pos, progress: usize) !usize {
    var queue = std.ArrayList(State).init(allocator);
    defer queue.deinit();

    try queue.append(.{ .pos = .{ .row = 0, .col = 0 }, .steps = 0 });

    var visited = std.AutoHashMap(Pos, void).init(allocator);
    defer visited.deinit();

    while (queue.items.len > 0) {
        const state = queue.orderedRemove(0);

        if (visited.get(.{ .row = state.pos.row, .col = state.pos.col }) != null) {
            continue;
        }

        try visited.put(.{ .row = state.pos.row, .col = state.pos.col }, {});

        if (state.pos.row == width - 1 and state.pos.col == height - 1) {
            return state.steps;
        }

        for (DIRECTIONS) |dir| {
            const new_row = state.pos.row + dir.row;
            const new_col = state.pos.col + dir.col;

            const is_in_bounds = new_row >= 0 and new_row < width and new_col >= 0 and new_col < height;
            const is_blockade = blk: {
                for (blocks[0..progress]) |item| {
                    if (item.row == new_row and item.col == new_col) {
                        break :blk true;
                    }
                }

                break :blk false;
            };

            if (is_in_bounds and !is_blockade) {
                try queue.append(.{ .pos = .{ .row = new_row, .col = new_col }, .steps = state.steps + 1 });
            }
        }
    }

    return error.NoPathFound;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    const blocks = try parseInput(allocator, input);
    defer blocks.deinit();

    var low: usize = 0;
    var high: usize = blocks.items.len - 1;

    while (low != high) {
        const mid = @divFloor(low + high, 2);
        if (findPath(allocator, blocks.items, mid + 1) == error.NoPathFound) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }

    print("Answer pos: {any}\n", .{blocks.items[low]});
}
