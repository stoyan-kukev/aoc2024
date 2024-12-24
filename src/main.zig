const std = @import("std");

fn parseInitialRegs(allocator: std.mem.Allocator, input: []const u8) !std.StringHashMap(u1) {
    var regs = std.StringHashMap(u1).init(allocator);
    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = std.mem.splitSequence(u8, line, ": ");
        const wire = parts.next().?;
        const value = try std.fmt.parseInt(u1, parts.next().?, 10);
        try regs.put(wire, value);
    }
    return regs;
}

fn executeGate(allocator: std.mem.Allocator, gate: []const u8, regs: *std.StringHashMap(u1)) !void {
    var parts = std.mem.splitSequence(u8, gate, " -> ");
    const expr = parts.next().?;
    const res_wire = parts.next().?;

    var expr_parts = std.mem.splitSequence(u8, expr, " ");
    const x = expr_parts.next().?;
    const op = expr_parts.next().?;
    const y = expr_parts.next().?;

    const a = regs.get(x) orelse return error.NeedToWait;
    const b = regs.get(y) orelse return error.NeedToWait;

    var result: u1 = undefined;
    if (std.mem.eql(u8, op, "AND")) {
        result = a & b;
    } else if (std.mem.eql(u8, op, "OR")) {
        result = a | b;
    } else if (std.mem.eql(u8, op, "XOR")) {
        result = a ^ b;
    }

    try regs.put(try allocator.dupe(u8, res_wire), result);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const regs_section = sections.next().?;
    const gates_section = sections.next().?;

    var regs = try parseInitialRegs(allocator, regs_section);
    defer {
        var it = regs.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        regs.deinit();
    }

    var unresolved = true;
    while (unresolved) {
        unresolved = false;
        var gates = std.mem.splitSequence(u8, gates_section, "\n");
        while (gates.next()) |gate| {
            if (gate.len == 0) continue;
            executeGate(allocator, gate, &regs) catch |err| switch (err) {
                error.NeedToWait => {
                    unresolved = true;
                },
                else => return err,
            };
        }
    }

    var z_values = std.ArrayList(u1).init(allocator);
    defer z_values.deinit();

    var cur_z: usize = 0;
    while (true) {
        const z_wire = try std.fmt.allocPrint(allocator, "z{d:0>2}", .{cur_z});
        defer allocator.free(z_wire);

        const val = regs.get(z_wire) orelse break;
        try z_values.append(val);
        cur_z += 1;
    }

    var bin_result: usize = 0;
    var i: usize = z_values.items.len;
    while (i > 0) {
        i -= 1;
        bin_result = (bin_result << 1) | z_values.items[i];
    }

    std.debug.print("Result: {}\n", .{bin_result});
}
