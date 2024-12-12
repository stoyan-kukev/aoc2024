const std = @import("std");

const DiskSector = struct {
    const Self = @This();

    id: ?usize,
    count: usize,
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u32) {
    var output = std.ArrayList(u32).init(allocator);
    errdefer output.deinit();

    for (input) |char| {
        if (!std.ascii.isDigit(char)) continue;
        try output.append(try std.fmt.parseInt(u32, &.{char}, 10));
    }

    return output;
}

fn countSectors(allocator: std.mem.Allocator, items: []u32) !std.ArrayList(DiskSector) {
    var sectors = std.ArrayList(DiskSector).init(allocator);

    var id: usize = 0;
    for (items, 0..) |num, i| {
        if (i % 2 != 0) {
            try sectors.append(.{ .id = null, .count = num });
        } else {
            try sectors.append(.{ .id = id, .count = num });
            id += 1;
        }
    }

    return sectors;
}

pub fn reorderSectors(sectors: *std.ArrayList(DiskSector)) !usize {
    var i: usize = 0;
    var j: usize = sectors.items.len - 1;

    while (i != j + 1) {
        if (sectors.items[j].id == null) {
            j -= 1;
            continue;
        }

        if (sectors.items[i].id != null) {
            i += 1;
            continue;
        }

        if (sectors.items[i].count > sectors.items[j].count) {
            sectors.items[i].count -= sectors.items[j].count;

            try sectors.insert(i, .{
                .id = sectors.items[j].id,
                .count = sectors.items[j].count,
            });

            i += 1;
            j -= 1;
        } else if (sectors.items[i].count == sectors.items[j].count) {
            sectors.items[i] = .{
                .id = sectors.items[j].id,
                .count = sectors.items[j].count,
            };

            sectors.items[j] = .{
                .id = null,
                .count = sectors.items[j].count,
            };

            i += 1;
            j -= 1;
        } else {
            sectors.items[j].count -= sectors.items[i].count;

            sectors.items[i] = .{
                .id = sectors.items[j].id,
                .count = sectors.items[i].count,
            };

            i += 1;
        }
    }

    return i;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    const map = try parseInput(allocator, input);
    defer map.deinit();

    var sectors = try countSectors(allocator, map.items);
    defer sectors.deinit();

    const midpoint = try reorderSectors(&sectors);

    var checksum: usize = 0;
    var id: usize = 0;
    for (0..midpoint) |i| {
        while (sectors.items[i].count != 0) {
            checksum += sectors.items[i].id.? * id;
            sectors.items[i].count -= 1;
            id += 1;
        }
    }

    std.debug.print("Checksum: {}\n", .{checksum});
}
