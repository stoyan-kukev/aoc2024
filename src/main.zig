const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const State = struct {
    a_move: Pos,
    b_move: Pos,
    target: Pos,

    const Pos = struct {
        x: i64,
        y: i64,
    };

    const Move = struct {
        x: i64,
        y: i64,
        tokens: i64,
    };
};

fn parseCoord(str: []const u8, coord: u8) !i64 {
    const index = std.mem.indexOfScalar(u8, str, coord) orelse return error.CoordNotFound;
    var j = index + 2;
    while (j < str.len and std.ascii.isDigit(str[j])) : (j += 1) {}
    return std.fmt.parseInt(i64, str[index + 2 .. j], 10);
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !ArrayList(State) {
    var states = ArrayList(State).init(allocator);
    errdefer states.deinit();

    var iter = std.mem.splitSequence(u8, input, "\n\n");
    while (iter.next()) |machine| {
        var line_iter = std.mem.splitScalar(u8, machine, '\n');

        const btn_a = line_iter.next() orelse return error.InvalidInput;
        const btn_b = line_iter.next() orelse return error.InvalidInput;
        const coords = line_iter.next() orelse return error.InvalidInput;

        const state = State{
            .a_move = .{
                .x = try parseCoord(btn_a, 'X'),
                .y = try parseCoord(btn_a, 'Y'),
            },
            .b_move = .{
                .x = try parseCoord(btn_b, 'X'),
                .y = try parseCoord(btn_b, 'Y'),
            },
            .target = .{
                .x = try parseCoord(coords, 'X'),
                .y = try parseCoord(coords, 'Y'),
            },
        };

        try states.append(state);
    }

    return states;
}

fn solveState(state: State, allocator: std.mem.Allocator) !?i64 {
    var queue = ArrayList(struct { x: i64, y: i64, a_presses: i64, b_presses: i64, tokens: i64 }).init(allocator);
    defer queue.deinit();

    var visited = AutoHashMap(struct { x: i64, y: i64, a_presses: i64, b_presses: i64 }, void).init(allocator);
    defer visited.deinit();

    try queue.append(.{ .x = 0, .y = 0, .a_presses = 0, .b_presses = 0, .tokens = 0 });

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);

        if (current.x == state.target.x and current.y == state.target.y) {
            return current.tokens;
        }

        if (current.a_presses > 100 or current.b_presses > 100) {
            continue;
        }

        const key = .{ .x = current.x, .y = current.y, .a_presses = current.a_presses, .b_presses = current.b_presses };
        if (visited.contains(key)) continue;
        try visited.put(key, {});

        // Try A button
        if (current.a_presses < 100) {
            try queue.append(.{
                .x = current.x + state.a_move.x,
                .y = current.y + state.a_move.y,
                .a_presses = current.a_presses + 1,
                .b_presses = current.b_presses,
                .tokens = current.tokens + 3,
            });
        }

        // Try B button
        if (current.b_presses < 100) {
            try queue.append(.{
                .x = current.x + state.b_move.x,
                .y = current.y + state.b_move.y,
                .a_presses = current.a_presses,
                .b_presses = current.b_presses + 1,
                .tokens = current.tokens + 1,
            });
        }
    }

    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = @embedFile("input.txt");
    const states = try parseInput(allocator, input);
    defer states.deinit();

    var total_tokens: i64 = 0;
    for (states.items) |state| {
        if (try solveState(state, allocator)) |tokens| {
            total_tokens += tokens;
        } else {
            print("No solution for state\n", .{});
        }
    }

    print("Total tokens: {}\n", .{total_tokens});
}
