const std = @import("std");
const print = std.debug.print;

fn mix(secret: usize, result: usize) usize {
    return secret ^ result;
}

fn prune(secret: usize) usize {
    return @mod(secret, 16777216);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var nums = std.ArrayList(usize).init(allocator);
    defer nums.deinit();

    const input = @embedFile("input.txt");
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len < 1) continue;

        try nums.append(try std.fmt.parseInt(usize, std.mem.trim(u8, line, "\n"), 10));
    }

    var sum: usize = 0;
    for (nums.items) |*num| {
        for (0..2000) |_| {
            num.* = prune(mix(num.*, num.* * 64));
            num.* = prune(mix(num.*, @divFloor(num.*, 32)));
            num.* = prune(mix(num.*, num.* * 2048));
        }

        sum += num.*;
    }

    print("Sum: {}\n", .{sum});
}
