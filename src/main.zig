const std = @import("std");
const print = std.debug.print;

const HeightMap = [5]isize;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var keys = std.ArrayList(HeightMap).init(allocator);
    defer keys.deinit();

    var locks = std.ArrayList(HeightMap).init(allocator);
    defer locks.deinit();

    var iter = std.mem.split(u8, input, "\n\n");
    while (iter.next()) |section| {
        var line_iter = std.mem.split(u8, section, "\n");
        const first_row = line_iter.next().?;
        if (first_row[0] == '#') {
            var height_map = [5]isize{ 6, 6, 6, 6, 6 };

            while (line_iter.next()) |line| {
                for (0..line.len) |i| {
                    if (line[i] == '.') {
                        height_map[i] -= 1;
                    }
                }
            }

            try locks.append(height_map);
        } else if (first_row[0] == '.') {
            var height_map = [5]isize{ -1, -1, -1, -1, -1 };

            while (line_iter.next()) |line| {
                for (0..line.len) |i| {
                    if (line[i] == '#') {
                        height_map[i] += 1;
                    }
                }
            }

            try keys.append(height_map);
        }
    }

    var valid_combos: usize = 0;

    for (locks.items) |lock| {
        for (keys.items) |key| {
            var is_valid_combo = true;

            for (0..lock.len) |i| {
                if (lock[i] + key[i] > 5) {
                    is_valid_combo = false;
                }
            }

            if (is_valid_combo) valid_combos += 1;
        }
    }

    print("Valid combos: {}\n", .{valid_combos});
}
