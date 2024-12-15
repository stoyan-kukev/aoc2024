const std = @import("std");

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u64) {
    var output = std.ArrayList(u64).init(allocator);
    errdefer output.deinit();

    var iter = std.mem.splitSequence(u8, std.mem.trim(u8, input, "\n"), " ");
    while (iter.next()) |number| {
        const num = std.fmt.parseInt(u64, number, 10) catch continue;
        try output.append(num);
    }

    return output;
}

fn printNums(nums: []u64) void {
    for (nums) |num| {
        std.debug.print("{} ", .{num});
    }
    std.debug.print("\n", .{});
}

fn countDigits(num: u64) usize {
    if (num == 0) return 1;

    return @intFromFloat(@floor(@log10(@as(f64, @floatFromInt(num)))) + 1);
}

fn evaluateStep(nums: *std.ArrayList(u64)) !void {
    var i: usize = 0;
    while (i < nums.items.len) : (i += 1) {
        const digit_count = countDigits(nums.items[i]);

        if (nums.items[i] == 0) {
            nums.items[i] = 1;
        } else if (digit_count % 2 == 0) {
            const divisor = std.math.pow(u64, 10, digit_count / 2);

            const first_half: u64 = nums.items[i] / divisor;
            const second_half: u64 = nums.items[i] % divisor;

            nums.items[i] = second_half;
            try nums.insert(i, first_half);
            i += 1;
        } else {
            nums.items[i] *= 2024;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var numbers = try parseInput(allocator, input);
    defer numbers.deinit();

    for (0..75) |i| {
        try evaluateStep(&numbers);
        std.debug.print("Done {}!\n", .{i});
    }

    std.debug.print("Count: {}\n", .{numbers.items.len});
}
