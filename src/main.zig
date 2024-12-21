const std = @import("std");
const print = std.debug.print;

const Regs = struct {
    a: i64 = 0,
    b: i64 = 0,
    c: i64 = 0,
    rip: usize = 0,
};

const Opcode = u3;

const Instruction = struct {
    opcode: Opcode,
    operand: Opcode,
};

const State = struct {
    const Self = @This();

    regs: Regs,
    output: std.ArrayList(i64),

    fn init(allocator: std.mem.Allocator, regs: Regs) State {
        var state: State = undefined;
        state.regs = regs;
        state.output = std.ArrayList(i64).init(allocator);

        return state;
    }

    fn deinit(self: *Self) void {
        self.output.deinit();
    }
};

fn parseRegsFromInput(input: []const u8) !Regs {
    var output: Regs = undefined;

    var input_iter = std.mem.splitSequence(u8, input, "\n");
    inline for (&.{ "a", "b", "c" }) |field| {
        const str = input_iter.next().?;
        var str_iter = std.mem.splitSequence(u8, str, ":");
        _ = str_iter.next().?;

        const num = std.mem.trim(u8, str_iter.next().?, " ");
        @field(output, field) = try std.fmt.parseInt(i64, num, 10);
    }

    output.rip = 0;

    return output;
}

fn parseInstructionsFromInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Instruction) {
    var instructions = std.ArrayList(Instruction).init(allocator);
    errdefer instructions.deinit();

    var str_iter = std.mem.splitSequence(u8, input, ":");
    _ = str_iter.next().?;

    const opcodes = std.mem.trim(u8, std.mem.trim(u8, str_iter.next().?, "\n"), " ");
    var opcodes_iter = std.mem.splitSequence(u8, opcodes, ",");
    while (opcodes_iter.next()) |opcode| {
        const instr = try std.fmt.parseInt(u3, opcode, 10);
        const operand = try std.fmt.parseInt(u3, opcodes_iter.next().?, 10);

        try instructions.append(.{ .opcode = instr, .operand = operand });
    }

    return instructions;
}

fn getComboOperand(state: *State, operand: Opcode) i64 {
    return switch (operand) {
        0, 1, 2, 3 => @intCast(operand),
        4 => state.regs.a,
        5 => state.regs.b,
        6 => state.regs.c,
        else => unreachable,
    };
}

fn executeInstruction(state: *State, instr: Instruction) !void {
    var should_inc_rip = true;

    switch (instr.opcode) {
        0 => {
            const combo_operand = std.math.pow(i64, 2, getComboOperand(state, instr.operand));
            state.regs.a = @divTrunc(state.regs.a, combo_operand);
        },
        1 => {
            state.regs.b ^= instr.operand;
        },
        2 => {
            state.regs.b = @mod(getComboOperand(state, instr.operand), 8);
        },
        3 => {
            if (state.regs.a != 0) {
                state.regs.rip = instr.operand;
                should_inc_rip = false;
            }
        },
        4 => {
            state.regs.b ^= state.regs.c;
        },
        5 => {
            const val = @mod(getComboOperand(state, instr.operand), 8);
            try state.output.append(val);
        },
        6 => {
            const combo_operand = std.math.pow(i64, 2, getComboOperand(state, instr.operand));
            state.regs.b = @divTrunc(state.regs.a, combo_operand);
        },
        7 => {
            const combo_operand = std.math.pow(i64, 2, getComboOperand(state, instr.operand));
            state.regs.c = @divTrunc(state.regs.a, combo_operand);
        },
    }

    if (should_inc_rip) {
        state.regs.rip += 1;
    }
}

fn convertInstructionsToOutput(allocator: std.mem.Allocator, slice: []Instruction) !std.ArrayList(i64) {
    var output = std.ArrayList(i64).init(allocator);

    for (slice) |item| {
        try output.append(item.opcode);
        try output.append(item.operand);
    }

    return output;
}

fn getOutputsFromComputer(
    allocator: std.mem.Allocator,
    a: i64,
    regs: Regs,
    instructions: *const std.ArrayList(Instruction),
) ![]i64 {
    var local_regs = regs;
    local_regs.a = a;

    var state = State.init(allocator, local_regs);
    defer state.deinit();

    while (state.regs.rip != instructions.items.len) {
        const instruction = instructions.items[state.regs.rip];
        try executeInstruction(&state, instruction);
    }

    return try state.output.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var section_iter = std.mem.splitSequence(u8, input, "\n\n");

    const regs_section = section_iter.next().?;
    const regs = try parseRegsFromInput(regs_section);

    const program_section = section_iter.next().?;
    const instructions = try parseInstructionsFromInput(allocator, program_section);
    defer instructions.deinit();

    var candidates = std.ArrayList(i64).init(allocator);
    defer candidates.deinit();

    try candidates.append(0);
    for (0..instructions.items.len) |l| {
        var next_candidates = std.ArrayList(i64).init(allocator);
        defer next_candidates.deinit();

        for (candidates.items) |val| {
            for (0..8) |i| {
                const target = (val << 3) + @as(i64, @intCast(i));

                const outputs = try getOutputsFromComputer(allocator, target, regs, &instructions);
                defer allocator.free(outputs);

                const program_suffix = instructions.items[instructions.items.len - l - 1 ..];
                const programs = try convertInstructionsToOutput(allocator, program_suffix);
                defer programs.deinit();

                if (std.mem.eql(i64, outputs, programs.items)) {
                    print("      Match found: {}\n", .{target});
                    try next_candidates.append(target);
                }
            }
        }

        candidates.clearAndFree();
        try candidates.appendSlice(next_candidates.items);
    }

    if (candidates.items.len == 0) {
        print("No valid candidates found.\n", .{});
        return;
    }
    print("Answer: {}\n", .{std.mem.min(i64, candidates.items)});
}
