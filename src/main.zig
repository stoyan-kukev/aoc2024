const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const State = struct {
    a_move: Pos,
    b_move: Pos,
    target: Pos,

    const Pos = struct {
        x: f64,
        y: f64,
    };
};

fn parseCoord(str: []const u8, coord: u8) !f64 {
    const index = std.mem.indexOfScalar(u8, str, coord) orelse return error.CoordNotFound;
    var j = index + 2;
    while (j < str.len and std.ascii.isDigit(str[j])) : (j += 1) {}
    return @floatFromInt(try std.fmt.parseInt(i64, str[index + 2 .. j], 10));
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
                .x = try parseCoord(coords, 'X') + 10000000000000,
                .y = try parseCoord(coords, 'Y') + 10000000000000,
            },
        };

        try states.append(state);
    }

    return states;
}

fn solveState(state: State) i64 {
    const n1 = state.target.x * state.b_move.y - state.target.y * state.b_move.x;
    const dn1 = state.a_move.x * state.b_move.y - state.a_move.y * state.b_move.x;

    const a = n1 / dn1;

    const n2 = state.target.x - state.a_move.x * a;
    const dn2 = state.b_move.x;

    const b = n2 / dn2;

    if (@mod(a, 1) == 0 and @mod(b, 1) == 0) {
        return @intFromFloat(a * 3 + b);
    }

    return 0;
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
        total_tokens += solveState(state);
    }

    print("Total tokens: {}\n", .{total_tokens});
}
