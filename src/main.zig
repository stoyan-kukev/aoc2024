const std = @import("std");
const print = std.debug.print;

const Formula = struct {
    op: []const u8,
    x: []const u8,
    y: []const u8,
};

const CircuitError = error{
    OutOfMemory,
    InvalidFormat,
};

fn makeWire(allocator: std.mem.Allocator, char: []const u8, num: usize) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}{d:0>2}", .{ char, num });
}

fn verifyZ(formulas: std.StringHashMap(Formula), wire: []const u8, num: usize) bool {
    const formula = formulas.get(wire) orelse return false;
    if (!std.mem.eql(u8, formula.op, "XOR")) return false;

    if (num == 0) {
        const inputs = [_][]const u8{ formula.x, formula.y };
        return std.mem.eql(u8, inputs[0], "x00") and std.mem.eql(u8, inputs[1], "y00") or
            std.mem.eql(u8, inputs[0], "y00") and std.mem.eql(u8, inputs[1], "x00");
    }

    return (verifyIntermediateXor(formulas, formula.x, num) and verifyCarryBit(formulas, formula.y, num)) or
        (verifyIntermediateXor(formulas, formula.y, num) and verifyCarryBit(formulas, formula.x, num));
}

fn verifyIntermediateXor(formulas: std.StringHashMap(Formula), wire: []const u8, num: usize) bool {
    const formula = formulas.get(wire) orelse return false;
    if (!std.mem.eql(u8, formula.op, "XOR")) return false;

    var x_wire_buf: [32]u8 = undefined;
    var y_wire_buf: [32]u8 = undefined;
    const x_wire = std.fmt.bufPrint(&x_wire_buf, "x{d:0>2}", .{num}) catch return false;
    const y_wire = std.fmt.bufPrint(&y_wire_buf, "y{d:0>2}", .{num}) catch return false;

    return (std.mem.eql(u8, formula.x, x_wire) and std.mem.eql(u8, formula.y, y_wire)) or
        (std.mem.eql(u8, formula.x, y_wire) and std.mem.eql(u8, formula.y, x_wire));
}

fn verifyCarryBit(formulas: std.StringHashMap(Formula), wire: []const u8, num: usize) bool {
    const formula = formulas.get(wire) orelse return false;

    if (num == 1) {
        if (!std.mem.eql(u8, formula.op, "AND")) return false;
        return (std.mem.eql(u8, formula.x, "x00") and std.mem.eql(u8, formula.y, "y00")) or
            (std.mem.eql(u8, formula.x, "y00") and std.mem.eql(u8, formula.y, "x00"));
    }

    if (!std.mem.eql(u8, formula.op, "OR")) return false;
    return (verifyDirectCarry(formulas, formula.x, num - 1) and verifyRecarry(formulas, formula.y, num - 1)) or
        (verifyDirectCarry(formulas, formula.y, num - 1) and verifyRecarry(formulas, formula.x, num - 1));
}

fn verifyDirectCarry(formulas: std.StringHashMap(Formula), wire: []const u8, num: usize) bool {
    const formula = formulas.get(wire) orelse return false;
    if (!std.mem.eql(u8, formula.op, "AND")) return false;

    var x_wire_buf: [32]u8 = undefined;
    var y_wire_buf: [32]u8 = undefined;
    const x_wire = std.fmt.bufPrint(&x_wire_buf, "x{d:0>2}", .{num}) catch return false;
    const y_wire = std.fmt.bufPrint(&y_wire_buf, "y{d:0>2}", .{num}) catch return false;

    return (std.mem.eql(u8, formula.x, x_wire) and std.mem.eql(u8, formula.y, y_wire)) or
        (std.mem.eql(u8, formula.x, y_wire) and std.mem.eql(u8, formula.y, x_wire));
}

fn verifyRecarry(formulas: std.StringHashMap(Formula), wire: []const u8, num: usize) bool {
    const formula = formulas.get(wire) orelse return false;
    if (!std.mem.eql(u8, formula.op, "AND")) return false;

    return (verifyIntermediateXor(formulas, formula.x, num) and verifyCarryBit(formulas, formula.y, num)) or
        (verifyIntermediateXor(formulas, formula.y, num) and verifyCarryBit(formulas, formula.x, num));
}

fn progress(formulas: std.StringHashMap(Formula), allocator: std.mem.Allocator) !usize {
    var i: usize = 0;
    while (true) {
        const z_wire = try makeWire(allocator, "z", i);
        defer allocator.free(z_wire);

        if (!verifyZ(formulas, z_wire, i)) break;
        i += 1;
    }
    return i;
}

fn swapFormulas(formulas: *std.StringHashMap(Formula), x: []const u8, y: []const u8) void {
    if (formulas.get(x)) |fx| {
        if (formulas.get(y)) |fy| {
            formulas.put(x, fy) catch return;
            formulas.put(y, fx) catch return;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    _ = sections.next();
    const gates_section = sections.next().?;

    var formulas = std.StringHashMap(Formula).init(allocator);
    defer {
        var it = formulas.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
        }
        formulas.deinit();
    }

    var lines = std.mem.splitSequence(u8, gates_section, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitSequence(u8, line, " -> ");
        const expr = parts.next().?;
        const z = parts.next().?;

        var expr_parts = std.mem.splitSequence(u8, expr, " ");
        const x = expr_parts.next().?;
        const op = expr_parts.next().?;
        const y = expr_parts.next().?;

        try formulas.put(try allocator.dupe(u8, z), Formula{
            .op = op,
            .x = x,
            .y = y,
        });
    }

    var swaps = std.ArrayList([]u8).init(allocator);
    defer {
        for (swaps.items) |swap| {
            allocator.free(swap);
        }
        swaps.deinit();
    }

    var swap_count: usize = 0;
    while (swap_count < 4) : (swap_count += 1) {
        const baseline = try progress(formulas, allocator);
        var found_swap = false;

        var it1 = formulas.keyIterator();
        while (it1.next()) |x| {
            var it2 = formulas.keyIterator();
            while (it2.next()) |y| {
                if (std.mem.eql(u8, x.*, y.*)) continue;

                swapFormulas(&formulas, x.*, y.*);
                const new_progress = try progress(formulas, allocator);

                if (new_progress > baseline) {
                    try swaps.append(try allocator.dupe(u8, x.*));
                    try swaps.append(try allocator.dupe(u8, y.*));
                    found_swap = true;
                    break;
                }
                swapFormulas(&formulas, x.*, y.*);
            }
            if (found_swap) break;
        }
    }

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    for (swaps.items) |swap| {
        try list.append(swap);
    }

    std.sort.block([]const u8, list.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    for (list.items, 0..) |swap, i| {
        if (i > 0) print(",", .{});
        print("{s}", .{swap});
    }
    print("\n", .{});
}
