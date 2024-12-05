const std = @import("std");
const input = @embedFile("input.txt");

const Input = struct {
    page_restrictions: []const u8,
    page_order: []const u8,
};

const PageRestrictions = std.AutoArrayHashMap(u32, std.ArrayList(u32));

fn processInput(string: []const u8) Input {
    var lines = std.mem.splitSequence(u8, string, "\n\n");

    const page_restrictions = lines.next().?;
    const page_order = lines.next().?;

    return .{
        .page_restrictions = page_restrictions,
        .page_order = page_order,
    };
}

fn processPageRestrictions(
    allocator: std.mem.Allocator,
    page_restrictions: []const u8,
) !std.AutoArrayHashMap(u32, std.ArrayList(u32)) {
    var output = PageRestrictions.init(allocator);
    var iter = std.mem.splitSequence(u8, page_restrictions, "\n");

    while (iter.next()) |line| {
        var inner_iter = std.mem.splitSequence(u8, line, "|");

        const key = try std.fmt.parseInt(u32, inner_iter.next().?, 10);
        const value = try std.fmt.parseInt(u32, inner_iter.next().?, 10);

        if (output.getPtr(key)) |val_arr| {
            try val_arr.append(value);
        } else {
            var list = std.ArrayList(u32).init(allocator);
            try list.append(value);
            try output.put(key, list);
        }
    }

    return output;
}

fn processPageOrder(allocator: std.mem.Allocator, page_order: []const u8) !std.ArrayList([]const u32) {
    var output = std.ArrayList([]const u32).init(allocator);
    var iter = std.mem.splitSequence(u8, page_order, "\n");
    while (iter.next()) |line| {
        var list = std.ArrayList(u32).init(allocator);
        defer list.deinit();

        var inner_iter = std.mem.splitSequence(u8, line, ",");
        while (inner_iter.next()) |item| {
            const parsedItem = std.fmt.parseInt(u32, item, 10) catch continue;
            try list.append(parsedItem);
        }

        if (list.items.len > 0) {
            const new_sequence = try allocator.dupe(u32, list.items);
            try output.append(new_sequence);
        }
    }
    return output;
}
fn checkPageSequence(page_restrictions: PageRestrictions, sequence: []const u32) bool {
    for (sequence, 0..) |item, i| {
        if (page_restrictions.get(item)) |restrictions| {
            for (restrictions.items) |restriction| {
                var iter = std.mem.reverseIterator(sequence[0..i]);

                while (iter.next()) |item_to_check| {
                    if (item_to_check == restriction) {
                        return false;
                    }
                }
            }
        }
    }

    return true;
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = processInput(input);

    var page_restrictions = try processPageRestrictions(allocator, data.page_restrictions);
    defer {
        for (page_restrictions.values()) |v| {
            v.deinit();
        }
        page_restrictions.deinit();
    }

    var page_order = try processPageOrder(allocator, data.page_order);
    defer {
        for (page_order.items) |arr| {
            allocator.free(arr);
        }
        page_order.deinit();
    }

    var sum: u32 = 0;
    for (page_order.items) |sequence| {
        const valid_sequence = checkPageSequence(page_restrictions, sequence);
        if (valid_sequence) {
            sum += sequence[sequence.len / 2];
        }
    }

    std.debug.print("Sum is {}\n", .{sum});
}
