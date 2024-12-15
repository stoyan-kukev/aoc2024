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

fn findSectorById(sectors: *std.ArrayList(DiskSector), id: usize) !usize {
    for (sectors.items, 0..) |sector, i| {
        if (sector.id) |sec_id| {
            if (sec_id == id) {
                return i;
            }
        }
    }

    return error.CantFindSector;
}

pub fn reorderSectors(sectors: *std.ArrayList(DiskSector)) !void {
    var curr_id_to_check: usize = blk: {
        var max_id: usize = 0;
        for (sectors.items) |sector| {
            max_id = @max(max_id, sector.id orelse 0);
        }
        break :blk max_id;
    };

    while (curr_id_to_check != 0) : (curr_id_to_check -= 1) {
        var free_space_idx: usize = 0;
        const sec_to_move = try findSectorById(sectors, curr_id_to_check);

        while (free_space_idx < sec_to_move) : (free_space_idx += 1) {
            if (sectors.items[free_space_idx].id != null) continue;

            if (sectors.items[free_space_idx].count == sectors.items[sec_to_move].count) {
                sectors.items[free_space_idx].id = sectors.items[sec_to_move].id;
                sectors.items[sec_to_move].id = null;

                break;
            } else if (sectors.items[free_space_idx].count > sectors.items[sec_to_move].count) {
                sectors.items[free_space_idx].count -= sectors.items[sec_to_move].count;
                const sector_copy = sectors.items[sec_to_move];

                sectors.items[sec_to_move].id = null;
                try sectors.insert(free_space_idx, .{
                    .id = sector_copy.id,
                    .count = sector_copy.count,
                });

                break;
            }
        }
    }
}

fn mergeFreeSpaces(sectors: *std.ArrayList(DiskSector)) !void {
    var i: usize = 0;
    while (i < sectors.items.len) {
        if (sectors.items[i].id == null) {
            var acc: usize = sectors.items[i].count;
            const j: usize = i + 1;

            while (j < sectors.items.len and sectors.items[j].id == null) {
                acc += sectors.items[j].count;
                _ = sectors.orderedRemove(j);
            }

            if (acc > sectors.items[i].count) {
                sectors.items[i].count = acc;
            }
        }
        i += 1;
    }
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

    try reorderSectors(&sectors);
    try mergeFreeSpaces(&sectors);

    var checksum: usize = 0;
    var pos: usize = 0;
    for (sectors.items) |*sector| {
        if (sector.id == null) {
            pos += sector.count;
            continue;
        }

        while (sector.count > 0) {
            sector.count -= 1;
            checksum += sector.id.? * pos;
            pos += 1;
        }
    }

    std.debug.print("Checksum: {}\n", .{checksum});
}
