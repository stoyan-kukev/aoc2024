const std = @import("std");
const print = std.debug.print;

fn parsePatterns(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([]u8) {
    var output = std.ArrayList([]u8).init(allocator);

    var input_iter = std.mem.splitSequence(u8, std.mem.trim(u8, input, "\n"), ", ");
    while (input_iter.next()) |pattern| {
        try output.append(try allocator.dupe(u8, pattern));
    }

    return output;
}

fn parseDesigns(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([]u8) {
    var output = std.ArrayList([]u8).init(allocator);

    var input_iter = std.mem.splitSequence(u8, input, "\n");
    while (input_iter.next()) |line| {
        if (line.len < 1) continue;

        try output.append(try allocator.dupe(u8, line));
    }

    return output;
}

fn validPattern(design: []u8, patterns: [][]u8) bool {
    if (design.len == 0) {
        return true;
    }

    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, design, pattern)) {
            if (validPattern(design[pattern.len..], patterns)) {
                return true;
            }
        }
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var section_iter = std.mem.splitSequence(u8, input, "\n\n");
    const pattern_section = section_iter.next().?;
    const designs_section = section_iter.next().?;

    const patterns = try parsePatterns(allocator, pattern_section);
    defer {
        for (patterns.items) |pattern| {
            allocator.free(pattern);
        }
        patterns.deinit();
    }

    const designs = try parseDesigns(allocator, designs_section);
    defer {
        for (designs.items) |design| {
            allocator.free(design);
        }
        designs.deinit();
    }

    var valid_designs: usize = 0;
    for (designs.items) |design| {
        if (validPattern(design, patterns.items)) {
            valid_designs += 1;
        }
    }

    print("Valid designs: {}\n", .{valid_designs});
}
