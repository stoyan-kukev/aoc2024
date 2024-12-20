const std = @import("std");
const print = std.debug.print;

const State = struct {
    y: usize,
    x: usize,
    dir: u8, // 0=right, 1=down, 2=left, 3=up
};

const QueueItem = struct {
    cost: u32,
    state: State,

    pub fn lessThan(context: void, a: QueueItem, b: QueueItem) std.math.Order {
        _ = context;
        return std.math.order(a.cost, b.cost);
    }
};

const Position = struct {
    y: usize,
    x: usize,
};

const DIRS = [_][2]i32{
    [_]i32{ 0, 1 }, // right
    [_]i32{ 1, 0 }, // down
    [_]i32{ 0, -1 }, // left
    [_]i32{ -1, 0 }, // up
};

pub fn findStartAndEnd(maze: [][]const u8) struct { start: Position, end: Position } {
    var start = Position{ .y = 0, .x = 0 };
    var end = Position{ .y = 0, .x = 0 };

    for (maze, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == 'S') {
                start = .{ .y = y, .x = x };
            } else if (cell == 'E') {
                end = .{ .y = y, .x = x };
            }
        }
    }
    return .{ .start = start, .end = end };
}

pub fn findOptimalPaths(allocator: std.mem.Allocator, maze: [][]const u8) !struct {
    optimal_tiles: std.AutoHashMap(Position, void),
    min_cost: u32,
} {
    const positions = findStartAndEnd(maze);
    const start = positions.start;
    const end = positions.end;
    const height = maze.len;
    const width = maze[0].len;

    var costs = std.AutoHashMap(State, u32).init(allocator);
    defer costs.deinit();

    var pq = std.PriorityQueue(QueueItem, void, QueueItem.lessThan).init(allocator, {});
    defer pq.deinit();

    var min_end_cost: u32 = std.math.maxInt(u32);

    const initial_state = State{ .y = start.y, .x = start.x, .dir = 0 };
    try pq.add(.{ .cost = 0, .state = initial_state });
    try costs.put(initial_state, 0);

    while (pq.count() > 0) {
        const current = pq.remove();

        if (costs.get(current.state)) |best_cost| {
            if (current.cost > best_cost) continue;
        }

        if (current.cost > min_end_cost) continue;

        if (current.state.y == end.y and current.state.x == end.x) {
            min_end_cost = @min(min_end_cost, current.cost);
            continue;
        }

        const dir = DIRS[current.state.dir];
        const new_y = @as(i32, @intCast(current.state.y)) + dir[0];
        const new_x = @as(i32, @intCast(current.state.x)) + dir[1];

        if (new_y >= 0 and new_y < height and new_x >= 0 and new_x < width) {
            const new_y_usize = @as(usize, @intCast(new_y));
            const new_x_usize = @as(usize, @intCast(new_x));

            if (maze[new_y_usize][new_x_usize] != '#') {
                const new_state = State{
                    .y = new_y_usize,
                    .x = new_x_usize,
                    .dir = current.state.dir,
                };
                const new_cost = current.cost + 1;

                const should_add = if (costs.get(new_state)) |best_cost|
                    new_cost < best_cost
                else
                    true;

                if (should_add) {
                    try costs.put(new_state, new_cost);
                    try pq.add(.{ .cost = new_cost, .state = new_state });
                }
            }
        }

        for ([_]i32{ -1, 1 }) |turn| {
            const new_dir = @as(u8, @intCast(@mod(@as(i32, @intCast(current.state.dir)) + turn + 4, 4)));
            const new_state = State{
                .y = current.state.y,
                .x = current.state.x,
                .dir = new_dir,
            };
            const new_cost = current.cost + 1000;

            const should_add = if (costs.get(new_state)) |best_cost|
                new_cost < best_cost
            else
                true;

            if (should_add) {
                try costs.put(new_state, new_cost);
                try pq.add(.{ .cost = new_cost, .state = new_state });
            }
        }
    }

    var optimal_tiles = std.AutoHashMap(Position, void).init(allocator);

    var queue = std.ArrayList(struct {
        y: usize,
        x: usize,
        dir: u8,
        remaining_cost: u32,
    }).init(allocator);
    defer queue.deinit();

    var visited = std.AutoHashMap(struct {
        y: usize,
        x: usize,
        dir: u8,
        remaining_cost: u32,
    }, void).init(allocator);
    defer visited.deinit();

    for (0..4) |d| {
        try queue.append(.{
            .y = end.y,
            .x = end.x,
            .dir = @intCast(d),
            .remaining_cost = min_end_cost,
        });
    }

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);
        try optimal_tiles.put(.{ .y = current.y, .x = current.x }, {});

        if (current.remaining_cost < 0) continue;

        const visit_state = .{
            .y = current.y,
            .x = current.x,
            .dir = current.dir,
            .remaining_cost = current.remaining_cost,
        };
        if (visited.contains(visit_state)) continue;
        try visited.put(visit_state, {});

        const opposite_dir = @as(u8, @intCast(@mod(@as(i32, @intCast(current.dir)) + 2, 4)));
        const prev_dir = DIRS[opposite_dir];
        const prev_y = @as(i32, @intCast(current.y)) + prev_dir[0];
        const prev_x = @as(i32, @intCast(current.x)) + prev_dir[1];

        if (prev_y >= 0 and prev_y < height and prev_x >= 0 and prev_x < width) {
            const prev_y_usize = @as(usize, @intCast(prev_y));
            const prev_x_usize = @as(usize, @intCast(prev_x));

            if (maze[prev_y_usize][prev_x_usize] != '#') {
                const prev_state = State{
                    .y = prev_y_usize,
                    .x = prev_x_usize,
                    .dir = current.dir,
                };

                if (costs.get(prev_state)) |cost| {
                    if (cost == current.remaining_cost - 1) {
                        try queue.append(.{
                            .y = prev_y_usize,
                            .x = prev_x_usize,
                            .dir = current.dir,
                            .remaining_cost = current.remaining_cost - 1,
                        });
                    }
                }
            }
        }

        for (0..4) |prev_d| {
            if (prev_d == current.dir) continue;

            const turn_diff = @mod(@abs(@as(i32, @intCast(prev_d)) - @as(i32, @intCast(current.dir)) + 4), 4);
            if (turn_diff != 1 and turn_diff != 3) continue;

            const prev_state = State{
                .y = current.y,
                .x = current.x,
                .dir = @intCast(prev_d),
            };

            if (costs.get(prev_state)) |cost| {
                if (cost == current.remaining_cost - 1000) {
                    try queue.append(.{
                        .y = current.y,
                        .x = current.x,
                        .dir = @intCast(prev_d),
                        .remaining_cost = current.remaining_cost - 1000,
                    });
                }
            }
        }
    }

    return .{
        .optimal_tiles = optimal_tiles,
        .min_cost = min_end_cost,
    };
}

pub fn visualizePaths(allocator: std.mem.Allocator, maze: [][]const u8, optimal_tiles: std.AutoHashMap(Position, void)) ![][]u8 {
    var result = try allocator.alloc([]u8, maze.len);
    for (result[0..result.len], 0..) |*row, i| {
        row.* = try allocator.alloc(u8, maze[0].len);
        for (row.*, 0..) |*cell, j| {
            if (maze[i][j] == '#') {
                cell.* = '#';
            } else if (optimal_tiles.contains(.{ .y = i, .x = j })) {
                cell.* = 'O';
            } else {
                cell.* = '.';
            }
        }
    }
    return result;
}

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
    for (maze[0..maze.len]) |*row| {
        row.* = try allocator.alloc(u8, width);
    }
    defer {
        for (maze) |row| {
            allocator.free(row);
        }
        allocator.free(maze);
    }

    {
        lines = std.mem.split(u8, input, "\n");
        var y: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            @memcpy(maze[y], line);
            y += 1;
        }
    }

    const result = try findOptimalPaths(allocator, maze);
    print("Minimum cost path: {}\n", .{result.min_cost});
    print("Number of tiles in optimal paths: {}\n", .{result.optimal_tiles.count()});

    const visualization = try visualizePaths(allocator, maze, result.optimal_tiles);
    defer {
        for (visualization) |row| {
            allocator.free(row);
        }
        allocator.free(visualization);
    }

    print("\nVisualization of optimal paths:\n", .{});
    for (visualization) |row| {
        print("{s}\n", .{row});
    }
}
