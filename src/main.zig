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

    std.mem.sort(i32, list1.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, list2.items, {}, std.sort.asc(i32));

    var sum: u32 = 0;

    for (list1.items, list2.items) |value1, value2| {
        sum += @abs(value1 - value2);
    }

    std.log.info("{}", .{sum});
}
