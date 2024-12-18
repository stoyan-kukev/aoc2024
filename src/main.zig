const std = @import("std");
const print = std.debug.print;

const Vec = struct {
    x: isize,
    y: isize,
};

const Robot = struct {
    pos: Vec,
    dir: Vec,
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

fn solve(allocator: std.mem.Allocator, input: []const u8) !usize {
    var robots = try parseInput(allocator, input);
    defer robots.deinit();

    var min_entropy: usize = std.math.maxInt(usize);
    var best_iteration: usize = 0;

    for (0..@as(usize, @intCast(map_bounds.x * map_bounds.y))) |step| {
        var result = std.ArrayList(Vec).init(allocator);
        defer result.deinit();

        var current_robots = std.ArrayList(Robot).init(allocator);
        defer current_robots.deinit();
        for (robots.items) |robot| {
            try current_robots.append(Robot{
                .pos = .{
                    .x = @mod(robot.pos.x + robot.dir.x * @as(isize, @intCast(step)), map_bounds.x),
                    .y = @mod(robot.pos.y + robot.dir.y * @as(isize, @intCast(step)), map_bounds.y),
                },
                .dir = robot.dir,
            });
        }

        const ver_mid: isize = @divFloor(map_bounds.y - 1, 2);
        const hor_mid: isize = @divFloor(map_bounds.x - 1, 2);
        var q1: usize = 0;
        var q2: usize = 0;
        var q3: usize = 0;
        var q4: usize = 0;

        for (current_robots.items) |robot| {
            if (robot.pos.x == hor_mid or robot.pos.y == ver_mid) continue;

            if (robot.pos.x < hor_mid) {
                if (robot.pos.y < ver_mid) {
                    q1 += 1;
                } else {
                    q3 += 1;
                }
            } else {
                if (robot.pos.y < ver_mid) {
                    q2 += 1;
                } else {
                    q4 += 1;
                }
            }
        }

        const entropy = q1 * q3 * q2 * q4;

        if (entropy < min_entropy) {
            min_entropy = entropy;
            best_iteration = step;
        }
    }

    return best_iteration;
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = @embedFile("input.txt");
    const result = try solve(allocator, input);
    print("{}\n", .{result});
}
