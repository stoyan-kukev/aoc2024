const std = @import("std");

const input = @embedFile("input.txt");

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
        if (values.len <= 1) continue;

        var is_increasing: ?bool = null;
        var is_safe = true;

        for (1..values.len) |current| {
            const diff = values[current] - values[current - 1];

            if (@abs(diff) < 1 or @abs(diff) > 3) {
                is_safe = false;
                break;
            }

            if (is_increasing == null) {
                is_increasing = diff > 0;
            } else {
                if ((is_increasing.? and diff < 0) or (!is_increasing.? and diff > 0)) {
                    is_safe = false;
                    break;
                }
            }
        }

        if (is_safe) {
            safe_levels += 1;
        }
    }

    std.log.info("Safe levels: {}", .{safe_levels});
}
