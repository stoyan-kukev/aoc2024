const std = @import("std");

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.AutoHashMap(u64, u64) {
    var map = std.AutoHashMap(u64, u64).init(allocator);
    errdefer map.deinit();

    var iter = std.mem.splitSequence(u8, std.mem.trim(u8, input, "\n"), " ");
    while (iter.next()) |number| {
        const num = std.fmt.parseInt(u64, number, 10) catch continue;
        if (map.get(num)) |count| {
            map.put(num, count + 1) catch unreachable;
        } else {
            map.put(num, 1) catch unreachable;
        }
    }

    return map;
}

fn countDigits(num: u64) usize {
    if (num == 0) return 1;

    return @intFromFloat(@floor(@log10(@as(f64, @floatFromInt(num)))) + 1);
}

fn evaluateStep(
    freq_map: *std.AutoHashMap(u64, u64),
    allocator: std.mem.Allocator,
) !void {
    var next_map = std.AutoHashMap(u64, u64).init(allocator);
    defer next_map.deinit();

    var iter = freq_map.iterator();
    while (iter.next()) |entry| {
        const stone = entry.key_ptr.*;
        const count = entry.value_ptr.*;

        const digit_count = countDigits(stone);
        if (stone == 0) {
            if (next_map.get(1)) |existing_count| {
                try next_map.put(1, existing_count + count);
            } else {
                try next_map.put(1, count);
            }
        } else if (digit_count % 2 == 0) {
            const divisor = std.math.pow(u64, 10, digit_count / 2);
            const first_half: u64 = stone / divisor;
            const second_half: u64 = stone % divisor;

            if (next_map.get(first_half)) |existing_count| {
                try next_map.put(first_half, existing_count + count);
            } else {
                try next_map.put(first_half, count);
            }

            if (next_map.get(second_half)) |existing_count| {
                try next_map.put(second_half, existing_count + count);
            } else {
                try next_map.put(second_half, count);
            }
        } else {
            const new_value = stone * 2024;
            if (next_map.get(new_value)) |existing_count| {
                try next_map.put(new_value, existing_count + count);
            } else {
                try next_map.put(new_value, count);
            }
        }
    }

    freq_map.clearAndFree();
    var iter_next = next_map.iterator();
    while (iter_next.next()) |entry| {
        try freq_map.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var freq_map = try parseInput(allocator, input);
    defer freq_map.deinit();

    for (0..75) |_| {
        try evaluateStep(&freq_map, allocator);
    }

    var total_stones: u64 = 0;
    var iter = freq_map.iterator();
    while (iter.next()) |entry| {
        total_stones += entry.value_ptr.*;
    }

    std.debug.print("Stone count: {}\n", .{total_stones});
}
