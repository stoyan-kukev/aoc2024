const std = @import("std");
const print = std.debug.print;

pub const NetworkGraph = struct {
    connections: std.StringHashMap(std.StringHashMap(void)),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) NetworkGraph {
        return .{
            .connections = std.StringHashMap(std.StringHashMap(void)).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *NetworkGraph) void {
        var it = self.connections.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.connections.deinit();
    }

    pub fn addConnection(self: *NetworkGraph, comp1: []const u8, comp2: []const u8) !void {
        if (self.connections.getPtr(comp1)) |neighbors| {
            try neighbors.put(comp2, {});
        } else {
            var map = std.StringHashMap(void).init(self.allocator);
            try map.put(comp2, {});
            try self.connections.put(comp1, map);
        }

        if (self.connections.getPtr(comp2)) |neighbors| {
            try neighbors.put(comp1, {});
        } else {
            var map = std.StringHashMap(void).init(self.allocator);
            try map.put(comp1, {});
            try self.connections.put(comp2, map);
        }
    }

    pub fn areConnected(self: *const NetworkGraph, comp1: []const u8, comp2: []const u8) bool {
        if (self.connections.get(comp1)) |neighbors| {
            return neighbors.contains(comp2);
        }

        return false;
    }

    fn canonicalTriangle(allocator: std.mem.Allocator, parts: [3][]const u8) ![]u8 {
        var sorted = parts;

        for (0..2) |i| {
            for (0..2 - i) |j| {
                if (std.mem.lessThan(u8, sorted[j + 1], sorted[j])) {
                    const temp = sorted[j];
                    sorted[j] = sorted[j + 1];
                    sorted[j + 1] = temp;
                }
            }
        }

        return std.fmt.allocPrint(allocator, "{s} {s} {s}", .{ sorted[0], sorted[1], sorted[2] });
    }

    pub fn findTrianglesWithT(self: *const NetworkGraph) !std.ArrayList([]u8) {
        var result = std.ArrayList([]u8).init(self.allocator);
        errdefer {
            for (result.items) |item| {
                self.allocator.free(item);
            }
            result.deinit();
        }

        var seen = std.StringHashMap(void).init(self.allocator);
        defer seen.deinit();

        var it = self.connections.iterator();
        while (it.next()) |entry1| {
            const comp1 = entry1.key_ptr.*;

            var it2 = entry1.value_ptr.keyIterator();
            while (it2.next()) |comp2| {
                var it3 = entry1.value_ptr.keyIterator();

                while (it3.next()) |comp3| {
                    if (!std.mem.eql(u8, comp2.*, comp3.*) and self.areConnected(comp2.*, comp3.*)) {
                        if (comp1[0] == 't' or comp2.*[0] == 't' or comp3.*[0] == 't') {
                            const triangle = try canonicalTriangle(self.allocator, .{ comp1, comp2.*, comp3.* });

                            if (try seen.fetchPut(triangle, {}) == null) {
                                try result.append(triangle);
                            } else {
                                self.allocator.free(triangle);
                            }
                        }
                    }
                }
            }
        }

        return result;
    }
};

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) !NetworkGraph {
    var graph = NetworkGraph.init(allocator);
    var lines = std.mem.split(u8, input, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = std.mem.split(u8, line, "-");
        const comp1 = parts.next() orelse return error.InvalidInput;
        const comp2 = parts.next() orelse return error.InvalidInput;
        try graph.addConnection(comp1, comp2);
    }

    return graph;
}

fn isValidGroup(
    self: *const NetworkGraph,
    current_group: *std.ArrayList([]const u8),
    candidate: []const u8,
) bool {
    for (current_group.items) |item| {
        if (!self.areConnected(item, candidate)) {
            return false;
        }
    }
    return true;
}

fn findGroup(
    self: *const NetworkGraph,
    node: []const u8,
    current_group: *std.ArrayList([]const u8),
    visited: *std.StringHashMap(bool),
) !void {
    if (visited.contains(node)) return;
    try current_group.append(node);
    try visited.put(node, true);

    if (self.connections.get(node)) |neighbors| {
        var it = neighbors.iterator();
        while (it.next()) |neighbor| {
            if (isValidGroup(self, current_group, neighbor.key_ptr.*)) {
                try findGroup(self, neighbor.key_ptr.*, current_group, visited);
            }
        }
    }
}

fn less(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub fn findLargestGroup(self: *const NetworkGraph) ![]u8 {
    var largest_group = std.ArrayList([]const u8).init(self.allocator);
    defer largest_group.deinit();

    var current_group = std.ArrayList([]const u8).init(self.allocator);
    defer current_group.deinit();

    var visited = std.StringHashMap(bool).init(self.allocator);
    defer visited.deinit();

    var it = self.connections.iterator();
    while (it.next()) |entry| {
        const node = entry.key_ptr.*;
        if (!visited.contains(node)) {
            try findGroup(self, node, &current_group, &visited);

            if (current_group.items.len > largest_group.items.len) {
                largest_group.clearAndFree();
                for (current_group.items) |item| {
                    try largest_group.append(item);
                }
            }
        }
        current_group.clearAndFree();
    }

    std.mem.sort([]const u8, largest_group.items, {}, less);

    return try std.mem.join(self.allocator, ",", largest_group.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    var net_graph = try parseInput(allocator, input);
    defer net_graph.deinit();

    const group = try findLargestGroup(&net_graph);
    defer allocator.free(group);

    print("Largest group: {s}\n", .{group});
}
