const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const num_keypad = [4][3]?u8{
    [3]?u8{ '7', '8', '9' },
    [3]?u8{ '4', '5', '6' },
    [3]?u8{ '1', '2', '3' },
    [3]?u8{ null, '0', 'A' },
};

const dir_keypad = [2][3]?u8{
    [3]?u8{ null, '^', 'A' },
    [3]?u8{ '<', 'v', '>' },
};

const DIRS = [4]struct { x: i32, y: i32, c: u8 }{
    .{ .x = 1, .y = 0, .c = '>' },
    .{ .x = -1, .y = 0, .c = '<' },
    .{ .x = 0, .y = -1, .c = '^' },
    .{ .x = 0, .y = 1, .c = 'v' },
};

const Vec2 = @Vector(2, i32);

const Move = struct {
    from: u8,
    to: u8,
};

const State = struct {
    pos: Vec2,
    steps: []const u8,
};

const Sequences = struct {
    map: std.AutoHashMap(Move, [][]const u8),
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: Allocator) Sequences {
        return .{
            .map = std.AutoHashMap(Move, [][]const u8).init(allocator),
            .arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *Sequences) void {
        self.map.deinit();
        self.arena.deinit();
    }
};

fn computeSeqs(allocator: Allocator, keypad: anytype) !Sequences {
    var sequences = Sequences.init(allocator);
    const arena = sequences.arena.allocator();

    var pos = std.AutoHashMap(u8, Vec2).init(arena);
    defer pos.deinit();

    for (keypad, 0..) |row, j| {
        for (row, 0..) |cell, i| {
            if (cell != null) {
                try pos.put(cell.?, Vec2{ @intCast(i), @intCast(j) });
            }
        }
    }

    var iter = pos.keyIterator();
    while (iter.next()) |x| {
        var inner_iter = pos.keyIterator();
        while (inner_iter.next()) |y| {
            if (x.* == y.*) {
                var path = try arena.alloc([]const u8, 1);
                path[0] = try arena.dupe(u8, "A");
                try sequences.map.put(.{ .from = x.*, .to = y.* }, path);
                continue;
            }

            var possibilities = std.ArrayList([]const u8).init(arena);
            var queue = std.ArrayList(State).init(arena);
            try queue.append(.{
                .pos = pos.get(x.*).?,
                .steps = "",
            });

            var most_optimal: usize = 9999;

            while (queue.items.len > 0) {
                const state = queue.orderedRemove(0);

                for (DIRS) |dir| {
                    if (state.pos[0] + dir.x < 0 or state.pos[1] + dir.y < 0) continue;

                    const nc: usize = @intCast(state.pos[1] + dir.y);
                    const nr: usize = @intCast(state.pos[0] + dir.x);

                    if (nc >= keypad.len or nr >= keypad[0].len) continue;
                    if (keypad[nc][nr] == null) continue;

                    if (keypad[nc][nr].? == y.*) {
                        if (most_optimal < state.steps.len + 1) break;
                        most_optimal = state.steps.len + 1;
                        const new_path = try std.fmt.allocPrint(arena, "{s}{c}A", .{ state.steps, dir.c });
                        try possibilities.append(new_path);
                    } else {
                        const new_steps = try std.fmt.allocPrint(arena, "{s}{c}", .{ state.steps, dir.c });
                        try queue.append(.{
                            .pos = Vec2{ @intCast(nr), @intCast(nc) },
                            .steps = new_steps,
                        });
                    }
                } else continue;
                break;
            }

            try sequences.map.put(
                .{ .from = x.*, .to = y.* },
                try possibilities.toOwnedSlice(),
            );
        }
    }

    return sequences;
}

fn cartesianProduct(allocator: Allocator, arrays: []const []const []const u8) ![][]const u8 {
    if (arrays.len == 0) return &[_][]const u8{};

    var total: usize = 1;
    for (arrays) |arr| {
        total *= arr.len;
    }

    var result = try allocator.alloc([]const u8, total);
    errdefer allocator.free(result);

    var indices = try allocator.alloc(usize, arrays.len);
    defer allocator.free(indices);
    @memset(indices, 0);

    var i: usize = 0;
    while (i < total) : (i += 1) {
        var total_len: usize = 0;
        for (arrays, indices) |arr, idx| {
            total_len += arr[idx].len;
        }

        var combined = try allocator.alloc(u8, total_len);
        var pos: usize = 0;
        for (arrays, indices) |arr, idx| {
            @memcpy(combined[pos..][0..arr[idx].len], arr[idx]);
            pos += arr[idx].len;
        }
        result[i] = combined;

        var j = arrays.len - 1;
        while (true) {
            indices[j] += 1;
            if (indices[j] < arrays[j].len) break;
            indices[j] = 0;
            if (j == 0) break;
            j -= 1;
        }
    }

    return result;
}

fn solve(allocator: Allocator, string: []const u8, seqs: *const Sequences) ![][]const u8 {
    var arena_alloc = std.heap.ArenaAllocator.init(allocator);
    const arena = arena_alloc.allocator();

    var options = try arena.alloc([]const []const u8, string.len);
    var prev: u8 = 'A';
    for (string, 0..) |curr, i| {
        const move = Move{ .from = prev, .to = curr };
        options[i] = seqs.map.get(move) orelse return error.InvalidMove;
        prev = curr;
    }

    return try cartesianProduct(allocator, options);
}

const MemoKey = struct {
    seq: []const u8,
    depth: u8,
};

const MemoKeyCtx = struct {
    pub fn hash(self: @This(), key: MemoKey) u64 {
        _ = self;
        var h = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&h, key.seq, .Deep);
        h.update(&.{key.depth});
        return h.final();
    }

    pub fn eql(self: @This(), key1: MemoKey, key2: MemoKey) bool {
        _ = self;
        return key1.depth == key2.depth and std.mem.eql(u8, key1.seq, key2.seq);
    }
};

const MemoMap = std.HashMap(MemoKey, usize, MemoKeyCtx, std.hash_map.default_max_load_percentage);

fn computeLengthsMap(allocator: std.mem.Allocator, seqs: *const Sequences) !std.AutoHashMap(Move, usize) {
    var lengths = std.AutoHashMap(Move, usize).init(allocator);
    var iter = seqs.map.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.*.len > 0) {
            try lengths.put(entry.key_ptr.*, entry.value_ptr.*[0].len);
        }
    }
    return lengths;
}

fn computeLength(
    seq: []const u8,
    depth: u8,
    dir_seqs: *const Sequences,
    dir_lengths: *const std.AutoHashMap(Move, usize),
    memo: *MemoMap,
    arena: Allocator,
) !usize {
    const key = MemoKey{ .seq = seq, .depth = depth };
    if (memo.get(key)) |cached| {
        return cached;
    }

    if (depth == 1) {
        var total: usize = 0;
        var prev: u8 = 'A';
        for (seq) |curr| {
            const move = Move{ .from = prev, .to = curr };
            total += dir_lengths.get(move) orelse return error.InvalidMove;
            prev = curr;
        }
        try memo.put(key, total);
        return total;
    }

    var total_length: usize = 0;
    var prev: u8 = 'A';

    for (seq) |curr| {
        const move = Move{ .from = prev, .to = curr };
        const possibilities = dir_seqs.map.get(move) orelse return error.InvalidMove;

        var local_min: usize = std.math.maxInt(usize);
        for (possibilities) |subseq| {
            const len = try computeLength(subseq, depth - 1, dir_seqs, dir_lengths, memo, arena);
            local_min = @min(local_min, len);
        }
        total_length += local_min;
        prev = curr;
    }

    try memo.put((try arena.dupe(MemoKey, &.{key}))[0], total_length);
    return total_length;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var num_seqs = try computeSeqs(allocator, num_keypad);
    defer num_seqs.deinit();

    var dir_seqs = try computeSeqs(allocator, dir_keypad);
    defer dir_seqs.deinit();

    var dir_lengths = try computeLengthsMap(allocator, &dir_seqs);
    defer dir_lengths.deinit();

    const input = @embedFile("input.txt");
    var lines = std.mem.splitScalar(u8, input, '\n');

    var total: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const solutions = try solve(arena.allocator(), line, &num_seqs);

        var memo = MemoMap.init(arena.allocator());

        var min_length: usize = std.math.maxInt(usize);
        for (solutions) |solution| {
            const length = try computeLength(
                solution,
                2,
                &dir_seqs,
                &dir_lengths,
                &memo,
                arena.allocator(),
            );
            min_length = @min(min_length, length);
        }

        const number = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);
        total += min_length * number;
    }

    print("Total: {}\n", .{total});
}
