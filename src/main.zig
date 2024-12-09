const std = @import("std");

const ExpressionEntry = struct {
    result: u64,
    expression: []const u8,
};

const Operator = enum {
    Add,
    Multiply,
};

fn generateExpressions(allocator: std.mem.Allocator, numbers: []const u64) !std.ArrayList([]const u8) {
    const num_count = numbers.len;
    if (num_count < 2) return error.NotEnoughNumbers;

    // Total combinations will be 2^(num_count-1) as each gap between numbers can be + or *
    const total_combinations = std.math.pow(u64, 2, @intCast(num_count - 1));

    var expressions = std.ArrayList([]const u8).init(allocator);
    errdefer expressions.deinit();

    var combination: u64 = 0;
    while (combination < total_combinations) : (combination += 1) {
        var expression_builder = std.ArrayList(u8).init(allocator);
        errdefer expression_builder.deinit();

        const first_num_str = try std.fmt.allocPrint(allocator, "{}", .{numbers[0]});
        defer allocator.free(first_num_str);
        try expression_builder.appendSlice(first_num_str);

        for (1..num_count) |i| {
            // Determine operator based on the bit in the current combination
            const op_bit = (combination >> @intCast(i - 1)) & 1;
            const op: Operator = if (op_bit == 0) .Add else .Multiply;

            try expression_builder.appendSlice(switch (op) {
                .Add => " + ",
                .Multiply => " * ",
            });

            const num_str = try std.fmt.allocPrint(allocator, "{}", .{numbers[i]});
            defer allocator.free(num_str);

            try expression_builder.appendSlice(num_str);
        }

        try expressions.append(try expression_builder.toOwnedSlice());
    }

    return expressions;
}

fn evaluateExpression(expr: []const u8) !u64 {
    var iter = std.mem.splitScalar(u8, expr, ' ');

    const first = iter.next() orelse return error.InvalidExpression;
    var total = try std.fmt.parseInt(u64, first, 10);

    while (true) {
        const op = iter.next() orelse break;

        const num_str = iter.next() orelse break;
        const number = try std.fmt.parseInt(u64, num_str, 10);

        total = switch (op[0]) {
            '+' => total + number,
            '*' => total * number,
            else => return error.InvalidOperator,
        };
    }

    return total;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(ExpressionEntry) {
    var output = std.ArrayList(ExpressionEntry).init(allocator);
    errdefer output.deinit();

    var line_iter = std.mem.splitSequence(u8, input, "\n");
    while (line_iter.next()) |line| {
        if (line.len < 1) continue;

        var seq_iter = std.mem.splitSequence(u8, line, ":");

        const expectedResultStr = std.mem.trim(u8, seq_iter.next().?, " ");
        const expectedResult = try std.fmt.parseInt(u64, expectedResultStr, 10);

        const expression = std.mem.trim(u8, seq_iter.next().?, " ");

        try output.append(.{
            .result = expectedResult,
            .expression = try allocator.dupe(u8, expression),
        });
    }

    return output;
}

fn listToNumbers(allocator: std.mem.Allocator, list: []const u8) !std.ArrayList(u64) {
    var output = std.ArrayList(u64).init(allocator);

    var iter = std.mem.splitScalar(u8, list, ' ');
    while (iter.next()) |num| {
        try output.append(try std.fmt.parseInt(u64, num, 10));
    }

    return output;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");
    var expressions = try parseInput(allocator, input);
    defer {
        for (expressions.items) |entry| {
            allocator.free(entry.expression);
        }
        expressions.deinit();
    }

    var sums = std.AutoHashMap(u64, void).init(allocator);
    defer sums.deinit();

    for (expressions.items) |entry| {
        var numbers = try listToNumbers(allocator, entry.expression);
        defer numbers.deinit();

        var generated_expressions = try generateExpressions(allocator, numbers.items);
        defer {
            for (generated_expressions.items) |expr| {
                allocator.free(expr);
            }
            generated_expressions.deinit();
        }

        for (generated_expressions.items) |expr| {
            const result = try evaluateExpression(expr);
            if (result == entry.result) {
                try sums.put(result, {});
            }
        }
    }

    var sum: u64 = 0;
    var iter = sums.keyIterator();
    while (iter.next()) |key| {
        sum += key.*;
    }

    std.debug.print("Final sum: {}\n", .{sum});
}
