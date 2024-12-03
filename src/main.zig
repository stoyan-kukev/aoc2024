const std = @import("std");

const input = @embedFile("input.txt");

pub fn main() !void {
    var sum: u64 = 0;

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (i + 7 < input.len and std.mem.startsWith(u8, input[i..], "mul(")) {
            var j = i + 4; // start after mul(
            const first_num_start = j;
            var first_num_end = j;
            var second_num_start: usize = undefined;
            var second_num_end: usize = undefined;

            var digit_count: u8 = 0;
            while (j < input.len and digit_count < 3 and input[j] >= '0' and input[j] <= '9') : (j += 1) {
                first_num_end = j + 1;
                digit_count += 1;
            }

            if (j < input.len and input[j] == ',') {
                second_num_start = j + 1;
                j += 1;
                digit_count = 0;

                while (j < input.len and digit_count < 3 and input[j] >= '0' and input[j] <= '9') : (j += 1) {
                    second_num_end = j + 1;
                    digit_count += 1;
                }

                if (j < input.len and input[j] == ')' and first_num_end > first_num_start and second_num_end > second_num_start) {
                    const first_num = try std.fmt.parseInt(u32, input[first_num_start..first_num_end], 10);
                    const second_num = try std.fmt.parseInt(u32, input[second_num_start..second_num_end], 10);

                    sum += first_num * second_num;
                }
            }
        }
    }

    std.log.info("Sum: {}", .{sum});
}
