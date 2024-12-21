const std = @import("std");
const print = std.debug.print;

const Regs = struct {
    a: i64,
    b: i64,
    c: i64,
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var section_iter = std.mem.splitSequence(u8, input, "\n\n");

    const regs_section = section_iter.next().?;
    const regs = try parseRegsFromInput(regs_section);
    var state = State.init(allocator, regs);
    defer state.deinit();

    const program_section = section_iter.next().?;
    const instructions = try parseInstructionsFromInput(allocator, program_section);
    defer instructions.deinit();

    while (state.regs.rip != instructions.items.len) {
        const instruction = instructions.items[state.regs.rip];
        try executeInstruction(&state, instruction);
    }

    print("Answer: ", .{});
    var i: usize = 0;
    while (i < state.output.items.len) : (i += 1) {
        print("{}", .{state.output.items[i]});
        if (i != state.output.items.len - 1) print(",", .{});
    }
    print("\n", .{});
}
