const std = @import("std");

const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var list1 = try std.ArrayList(i32).initCapacity(alloc, 1000);
    defer list1.deinit();

    var list2 = try std.ArrayList(i32).initCapacity(alloc, 1000);
    defer list2.deinit();

    var iter = std.mem.splitSequence(u8, input, "\n");
    while (iter.next()) |line| {
        var inner_iter = std.mem.splitSequence(u8, line, "   ");
        const val1 = inner_iter.next() orelse continue;
        const val2 = inner_iter.next() orelse continue;
        const value1 = std.fmt.parseUnsigned(i32, val1, 10) catch continue;
        const value2 = std.fmt.parseUnsigned(i32, val2, 10) catch continue;
        try list1.append(value1);
        try list2.append(value2);
    }

    var similarity_map = std.AutoArrayHashMap(i32, i32).init(alloc);
    defer similarity_map.deinit();

    for (list2.items) |val| {
        if (similarity_map.get(val)) |old_val| {
            try similarity_map.put(val, old_val + 1);
        } else {
            try similarity_map.put(val, 1);
        }
    }

    var sum: i32 = 0;

    for (list1.items) |value| {
        const similarity = similarity_map.get(value) orelse 0;
        sum += value * similarity;
        std.log.info("Adding {} to sum", .{value * similarity});
        std.log.info("Value: {}\tSimilarity: {}", .{ value, similarity });
    }

    std.log.info("{}", .{sum});
}
