const std = @import("std");
const input = @embedFile("input.txt");

const DAG = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    adj_list: std.AutoArrayHashMap(u32, std.ArrayList(u32)),

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .adj_list = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.adj_list.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.adj_list.deinit();
    }

    pub fn addEdge(self: *Self, from: u32, to: u32) !void {
        const adj_list = &self.adj_list;

        if (!adj_list.contains(from)) {
            try adj_list.put(from, std.ArrayList(u32).init(self.allocator));
        }

        if (!adj_list.contains(to)) {
            try adj_list.put(to, std.ArrayList(u32).init(self.allocator));
        }

        try adj_list.getPtr(from).?.append(to);
    }

    pub fn topologicalSort(self: *Self, input_sequence: []const u32) ![]u32 {
        var sorted_sequence = try self.allocator.dupe(u32, input_sequence);

        var changed = true;
        while (changed) {
            changed = false;
            for (0..sorted_sequence.len) |i| {
                for (0..sorted_sequence.len) |j| {
                    if (i < j) {
                        if (self.adj_list.get(sorted_sequence[j])) |neighbors| {
                            for (neighbors.items) |neighbor| {
                                if (neighbor == sorted_sequence[i]) {
                                    // Swap to respect dependency
                                    std.mem.swap(u32, &sorted_sequence[i], &sorted_sequence[j]);
                                    changed = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        return sorted_sequence;
    }
};

const Input = struct {
    page_restrictions: []const u8,
    page_order: []const u8,
};

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
) !DAG {
    var output = try DAG.init(allocator);
    var iter = std.mem.splitSequence(u8, page_restrictions, "\n");

    while (iter.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines
        var inner_iter = std.mem.splitSequence(u8, line, "|");

        const key = try std.fmt.parseInt(u32, inner_iter.next().?, 10);
        const value = try std.fmt.parseInt(u32, inner_iter.next().?, 10);

        try output.addEdge(key, value);
    }

    return output;
}

fn processPageOrder(allocator: std.mem.Allocator, page_order: []const u8) !std.ArrayList([]const u32) {
    var output = std.ArrayList([]const u32).init(allocator);
    var iter = std.mem.splitSequence(u8, page_order, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines
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

fn checkPageSequence(dag: *DAG, sequence: []const u32) bool {
    for (0..sequence.len) |i| {
        for (i + 1..sequence.len) |j| {
            if (dag.adj_list.contains(sequence[j])) {
                if (dag.adj_list.get(sequence[j])) |neighbors| {
                    for (neighbors.items) |neighbor| {
                        if (neighbor == sequence[i]) {
                            return false;
                        }
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
    defer page_restrictions.deinit();

    var page_order = try processPageOrder(allocator, data.page_order);
    defer {
        for (page_order.items) |arr| {
            allocator.free(arr);
        }
        page_order.deinit();
    }

    var incorrect_updates = std.ArrayList([]const u32).init(allocator);
    defer incorrect_updates.deinit();

    for (page_order.items) |sequence| {
        const valid_sequence = checkPageSequence(&page_restrictions, sequence);

        if (!valid_sequence) {
            const reordered = try page_restrictions.topologicalSort(sequence);
            defer allocator.free(reordered);

            try incorrect_updates.append(try allocator.dupe(u32, reordered));
        }
    }

    var incorrect_sum: u32 = 0;
    for (incorrect_updates.items) |update| {
        defer allocator.free(update);
        if (update.len > 0) {
            incorrect_sum += update[update.len / 2];
        }
    }

    std.debug.print("Sum of unordered sequences: {}\n", .{incorrect_sum});
}
