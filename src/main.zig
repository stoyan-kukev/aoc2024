const std = @import("std");
const print = std.debug.print;

const Vec = struct {
    row: isize,
    col: isize,

    fn eql(self: Vec, other: Vec) bool {
        return self.row == other.row and self.col == other.col;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = @embedFile("input.txt");
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const top = sections.next().?;
    const bottom = sections.next().?;

    var grid = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (grid.items) |*row| {
            row.deinit();
        }
        grid.deinit();
    }

    var lines = std.mem.splitSequence(u8, top, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var row = std.ArrayList(u8).init(allocator);

        for (line) |char| {
            switch (char) {
                '#' => try row.appendSlice("##"),
                'O' => try row.appendSlice("[]"),
                '.' => try row.appendSlice(".."),
                '@' => try row.appendSlice("@."),
                else => {},
            }
        }
        try grid.append(row);
    }

    var moves = std.ArrayList(Vec).init(allocator);
    defer moves.deinit();

    for (bottom) |char| {
        if (char == '\n') continue;
        try moves.append(switch (char) {
            '^' => .{ .row = -1, .col = 0 },
            'v' => .{ .row = 1, .col = 0 },
            '<' => .{ .row = 0, .col = -1 },
            '>' => .{ .row = 0, .col = 1 },
            else => continue,
        });
    }

    var robot = blk: {
        for (grid.items, 0..) |row, r| {
            for (row.items, 0..) |cell, c| {
                if (cell == '@') {
                    break :blk Vec{ .row = @intCast(r), .col = @intCast(c) };
                }
            }
        }
        unreachable;
    };

    for (moves.items) |move| {
        var targets = std.ArrayList(Vec).init(allocator);
        defer targets.deinit();

        try targets.append(robot);
        var i: usize = 0;
        var can_move = true;

        while (i < targets.items.len) : (i += 1) {
            const current = targets.items[i];
            const next = Vec{
                .row = current.row + move.row,
                .col = current.col + move.col,
            };

            if (next.row < 0 or next.col < 0 or
                next.row >= grid.items.len or
                next.col >= grid.items[0].items.len)
            {
                can_move = false;
                break;
            }

            var already_in_targets = false;
            for (targets.items) |target| {
                if (target.eql(next)) {
                    already_in_targets = true;
                    break;
                }
            }
            if (already_in_targets) continue;

            const next_char = grid.items[@intCast(next.row)].items[@intCast(next.col)];
            if (next_char == '#') {
                can_move = false;
                break;
            }

            if (next_char == '[') {
                try targets.append(next);
                try targets.append(.{ .row = next.row, .col = next.col + 1 });
            }
            if (next_char == ']') {
                try targets.append(next);
                try targets.append(.{ .row = next.row, .col = next.col - 1 });
            }
        }

        if (can_move) {
            var grid_copy = std.ArrayList(std.ArrayList(u8)).init(allocator);
            defer {
                for (grid_copy.items) |*row| {
                    row.deinit();
                }
                grid_copy.deinit();
            }

            for (grid.items) |row| {
                var new_row = std.ArrayList(u8).init(allocator);
                try new_row.appendSlice(row.items);
                try grid_copy.append(new_row);
            }

            grid.items[@intCast(robot.row)].items[@intCast(robot.col)] = '.';
            robot.row += move.row;
            robot.col += move.col;
            grid.items[@intCast(robot.row)].items[@intCast(robot.col)] = '@';

            for (targets.items[1..]) |target| {
                grid.items[@intCast(target.row)].items[@intCast(target.col)] = '.';
            }
            for (targets.items[1..]) |target| {
                const old_char = grid_copy.items[@intCast(target.row)].items[@intCast(target.col)];
                grid.items[@intCast(target.row + move.row)].items[@intCast(target.col + move.col)] = old_char;
            }
        }
    }

    // Calculate sum
    // NOTE: The left-most point of the box is always the left side [ of it
    var sum: usize = 0;
    for (grid.items, 0..) |row, r| {
        for (row.items, 0..) |cell, c| {
            if (cell == '[') {
                sum += 100 * r + c;
            }
        }
    }

    print("Sum: {}\n", .{sum});
}
