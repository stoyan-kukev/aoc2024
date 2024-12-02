const std = @import("std");

const input = @embedFile("input.txt");

fn isSequenceSafe(values: []const i32) bool {
    if (values.len <= 1) return false;

    var is_increasing: ?bool = null;

    for (1..values.len) |current| {
        const diff = values[current] - values[current - 1];

        if (@abs(diff) < 1 or @abs(diff) > 3) {
            return false;
        }

        if (is_increasing) |increasing| {
            if ((increasing and diff < 0) or (!increasing and diff > 0)) {
                return false;
            }
        } else {
            is_increasing = diff > 0;
        }
    }

    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var levels = try std.ArrayList([]i32).initCapacity(alloc, 1000);
    defer {
        for (levels.items) |level| {
            alloc.free(level);
        }
        levels.deinit();
    }

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        var values = try std.ArrayList(i32).initCapacity(alloc, 10);
        defer values.deinit();

        var inner_iter = std.mem.splitScalar(u8, line, ' ');
        while (inner_iter.next()) |item| {
            const value = std.fmt.parseInt(i32, item, 10) catch continue;
            try values.append(value);
        }

        if (values.items.len > 0) {
            try levels.append(try alloc.dupe(i32, values.items));
        }
    }

    var safe_levels: u32 = 0;

    for (levels.items) |values| {
        if (isSequenceSafe(values)) {
            safe_levels += 1;
            continue;
        }

        var is_safe_dampened = false;
        for (0..values.len) |skip_index| {
            var test_values = std.ArrayList(i32).init(alloc);
            defer test_values.deinit();

            for (0..values.len) |i| {
                if (i != skip_index) {
                    try test_values.append(values[i]);
                }
            }

            if (isSequenceSafe(test_values.items)) {
                is_safe_dampened = true;
                break;
            }
        }

        if (is_safe_dampened) {
            safe_levels += 1;
        }
    }

    std.log.info("Safe levels with Problem Dampner: {}", .{safe_levels});
}
