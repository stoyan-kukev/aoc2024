const std = @import("std");
const print = std.debug.print;

fn nextNum(x: usize) usize {
    var result = x;
    result ^= (result * 64) % 16777216;
    result ^= (result / 32) % 16777216;
    result ^= (result * 2048) % 16777216;
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var nums = std.ArrayList(usize).init(allocator);
    defer nums.deinit();

    const input = @embedFile("input.txt");
    var input_iter = std.mem.splitScalar(u8, input, '\n');
    while (input_iter.next()) |line| {
        if (line.len < 1) continue;

        try nums.append(try std.fmt.parseInt(usize, std.mem.trim(u8, line, "\n"), 10));
    }

    var seq_totals = std.AutoHashMap([4]i64, usize).init(allocator);
    defer seq_totals.deinit();

    for (nums.items) |initial_num| {
        var num = initial_num;
        var outputs = std.ArrayList(usize).init(allocator);
        defer outputs.deinit();

        for (0..2000) |_| {
            num = nextNum(num);
            try outputs.append(num % 10);
        }

        var seen = std.AutoHashMap([4]i64, void).init(allocator);
        defer seen.deinit();

        if (outputs.items.len < 5) continue;

        for (4..outputs.items.len) |i| {
            var seq: [4]i64 = undefined;
            for (0..4) |j| {
                const curr = @as(i64, @intCast(outputs.items[i - j]));
                const prev = @as(i64, @intCast(outputs.items[i - j - 1]));
                seq[3 - j] = curr - prev;
            }

            const gop = try seen.getOrPut(seq);
            if (gop.found_existing) continue;

            const n = outputs.items[i];
            const entry = try seq_totals.getOrPut(seq);
            if (entry.found_existing) {
                entry.value_ptr.* += n;
            } else {
                entry.value_ptr.* = n;
            }
        }
    }

    var max_total: usize = 0;
    var iter = seq_totals.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* > max_total) {
            max_total = entry.value_ptr.*;
        }
    }

    print("Max bananas: {}\n", .{max_total});
}
