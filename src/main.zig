const std = @import("std");

const ExpressionEntry = struct {
    target: u64,
    numbers: std.ArrayList(u64),
};

fn evaluate(
    numbers: []const u64,
    target: u64,
    index: usize,
    current: u64,
    allocator: std.mem.Allocator,
) bool {
    if (index == numbers.len) {
        return current == target;
    }

    const next = numbers[index];
    // Try addition
    if (evaluate(numbers, target, index + 1, current + next, allocator)) {
        return true;
    }
    // Try multiplication
    if (evaluate(numbers, target, index + 1, current * next, allocator)) {
        return true;
    }
    // Try concatenation
    var concat = current;
    var power_of_ten: u32 = 1;
    var temp = next;
    while (temp != 0) : (temp /= 10) {
        power_of_ten *= 10;
    }
    concat = concat * power_of_ten + next;
    if (evaluate(numbers, target, index + 1, concat, allocator)) {
        return true;
    }

    return false;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]ExpressionEntry {
    var output = std.ArrayList(ExpressionEntry).init(allocator);
    errdefer output.deinit();

    var line_iter = std.mem.splitSequence(u8, input, "\n");
    while (line_iter.next()) |line| {
        if (line.len < 1) continue;

        var seq_iter = std.mem.splitSequence(u8, line, ":");

        const targetStr = std.mem.trim(u8, seq_iter.next().?, " ");
        const target = try std.fmt.parseInt(u64, targetStr, 10);

        const expressionStr = std.mem.trim(u8, seq_iter.next().?, " ");
        const numbers = try parseNumbers(allocator, expressionStr);

        try output.append(.{
            .target = target,
            .numbers = numbers,
        });
    }

    return output.toOwnedSlice();
}

fn parseNumbers(allocator: std.mem.Allocator, str: []const u8) !std.ArrayList(u64) {
    var output = std.ArrayList(u64).init(allocator);
    errdefer output.deinit();

    var iter = std.mem.splitScalar(u8, str, ' ');
    while (iter.next()) |num_str| {
        const num = try std.fmt.parseInt(u64, num_str, 10);
        try output.append(num);
    }

    return output;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    const entries = try parseInput(allocator, input);
    defer {
        for (entries) |entry| {
            entry.numbers.deinit();
        }
        allocator.free(entries);
    }

    var sum: u64 = 0;
    for (entries) |entry| {
        if (evaluate(entry.numbers.items, entry.target, 1, entry.numbers.items[0], allocator)) {
            sum += entry.target;
        }
    }

    std.debug.print("Final sum: {}\n", .{sum});
}
