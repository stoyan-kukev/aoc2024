const std = @import("std");
const print = std.debug.print;

const State = struct {
    x: usize,
    y: usize,
    dir: u8, // 0=right, 1=down, 2=left, 3=up
};

const QueueItem = struct {
    cost: u32,
    forward_steps: u32,
    turns: u32,
    state: State,

    pub fn lessThan(context: void, a: QueueItem, b: QueueItem) std.math.Order {
        _ = context;
        return std.math.order(a.cost, b.cost);
    }
};

const DIRS = [_][2]i32{
    [_]i32{ 0, 1 },
    [_]i32{ 1, 0 },
    [_]i32{ 0, -1 },
    [_]i32{ -1, 0 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = @embedFile("input.txt");

    var lines = std.mem.split(u8, input, "\n");
    var height: usize = 0;
    var width: usize = 0;
    {
        var line_it = lines;
        while (line_it.next()) |line| {
            if (line.len == 0) continue;
            width = line.len;
            height += 1;
        }
    }

    var maze = try allocator.alloc([]u8, height);
    for (maze) |*row| {
        row.* = try allocator.alloc(u8, width);
    }
    defer {
        for (maze) |row| {
            allocator.free(row);
        }
        allocator.free(maze);
    }

    var start = State{ .y = 0, .x = 0, .dir = 0 };
    var end = State{ .y = 0, .x = 0, .dir = 0 };
    {
        lines = std.mem.split(u8, input, "\n");
        var y: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            for (line, 0..) |char, x| {
                maze[y][x] = char;
                if (char == 'S') {
                    start = .{ .y = y, .x = x, .dir = 0 };
                } else if (char == 'E') {
                    end = .{ .y = y, .x = x, .dir = 0 };
                }
            }
            y += 1;
        }
    }

    var visited = std.AutoHashMap(State, u32).init(allocator);
    defer visited.deinit();

    var pq = std.PriorityQueue(QueueItem, void, QueueItem.lessThan).init(allocator, {});
    defer pq.deinit();

    try pq.add(.{
        .cost = 0,
        .forward_steps = 0,
        .turns = 0,
        .state = start,
    });
    try visited.put(start, 0);

    while (pq.count() > 0) {
        const current = pq.remove();
        const state = current.state;

        if (state.y == end.y and state.x == end.x) {
            print("Total cost: {}\n", .{current.cost});
            return;
        }

        const dir = DIRS[state.dir];
        const new_y = @as(i32, @intCast(state.y)) + dir[0];
        const new_x = @as(i32, @intCast(state.x)) + dir[1];

        if (new_y >= 0 and new_y < height and new_x >= 0 and new_x < width) {
            const new_y_usize = @as(usize, @intCast(new_y));
            const new_x_usize = @as(usize, @intCast(new_x));

            if (maze[new_y_usize][new_x_usize] != '#') {
                const new_state = State{
                    .y = new_y_usize,
                    .x = new_x_usize,
                    .dir = state.dir,
                };
                const new_cost = current.cost + 1;

                if (visited.get(new_state) == null or visited.get(new_state).? > new_cost) {
                    try visited.put(new_state, new_cost);
                    try pq.add(.{
                        .cost = new_cost,
                        .forward_steps = current.forward_steps + 1,
                        .turns = current.turns,
                        .state = new_state,
                    });
                }
            }
        }

        // Try turning left and right
        for ([_]i32{ -1, 1 }) |turn| {
            const new_dir = @as(u8, @intCast(@mod(@as(i32, @intCast(state.dir)) + turn + 4, 4)));
            const new_state = State{
                .y = state.y,
                .x = state.x,
                .dir = new_dir,
            };
            const new_cost = current.cost + 1000;

            if (visited.get(new_state) == null or visited.get(new_state).? > new_cost) {
                try visited.put(new_state, new_cost);
                try pq.add(.{
                    .cost = new_cost,
                    .forward_steps = current.forward_steps,
                    .turns = current.turns + 1,
                    .state = new_state,
                });
            }
        }
    }

    print("No solution found\n", .{});
}
