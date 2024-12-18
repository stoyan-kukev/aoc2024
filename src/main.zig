const std = @import("std");
const print = std.debug.print;

const Vec = struct {
    x: isize,
    y: isize,
};

const Robot = struct {
    pos: Vec,
    dir: Vec,

    pub fn format(
        self: Robot,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Pos: ({}, {}) Vec: ({}, {}", .{
            self.pos.x, self.pos.y, self.dir.x, self.dir.y,
        });

        try writer.writeAll(")");
    }
};

const map_bounds: Vec = .{
    .x = 101,
    .y = 103,
};

fn parseVec(str: []const u8) !Vec {
    var iter = std.mem.splitSequence(u8, str[2..], ",");

    const x = try std.fmt.parseInt(isize, iter.next().?, 10);
    const y = try std.fmt.parseInt(isize, iter.next().?, 10);

    return .{
        .x = x,
        .y = y,
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Robot) {
    var output = std.ArrayList(Robot).init(allocator);

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        if (line.len < 1) continue;

        var str_iter = std.mem.splitSequence(u8, line, " ");
        const pos = try parseVec(str_iter.next().?);
        const dir = try parseVec(str_iter.next().?);

        try output.append(.{ .pos = pos, .dir = dir });
    }

    return output;
}

fn checkMiddleOfBounds(pos: Vec) bool {
    const middleX = map_bounds.x / 2;
    const middleY = map_bounds.y / 2;

    const xIsOutsideMiddle =
        if (map_bounds.x % 2 == 0)
        pos.x < middleX or pos.x >= middleX + 2
    else
        pos.x != middleX;

    const yIsOutsideMiddle =
        if (map_bounds.y % 2 == 0)
        pos.y < middleY or pos.y >= middleY + 2
    else
        pos.y != middleY;

    return xIsOutsideMiddle and yIsOutsideMiddle;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = @embedFile("input.txt");
    const robots = try parseInput(allocator, input);
    defer robots.deinit();

    for (robots.items) |*robot| {
        robot.pos.x += robot.dir.x * 100;
        robot.pos.y += robot.dir.y * 100;

        robot.pos.x = @mod(robot.pos.x, map_bounds.x);
        robot.pos.y = @mod(robot.pos.y, map_bounds.y);
    }

    var q1: usize = 0;
    var q2: usize = 0;
    var q3: usize = 0;
    var q4: usize = 0;

    for (robots.items) |robot| {
        if (!checkMiddleOfBounds(robot.pos)) continue;

        const isLeft = robot.pos.x < map_bounds.x / 2;
        const isTop = robot.pos.y < map_bounds.y / 2;

        if (isLeft and isTop) {
            q1 += 1;
        } else if (!isLeft and isTop) {
            q2 += 1;
        } else if (isLeft and !isTop) {
            q3 += 1;
        } else {
            q4 += 1;
        }
    }
    const safety_factor = q1 * q2 * q3 * q4;

    print("Safety factor: {}\n", .{safety_factor});
}
