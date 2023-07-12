const std = @import("std");
const Order = std.math.Order;

fn lessThan(context: void, a: u32, b: u32) Order {
    _ = context;
    return std.math.order(a, b);
}

const PQlt = std.PriorityQueue(u32, void, lessThan);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status) std.debug.print("Leak detected", .{});
    }

    var contents = try std.fs.cwd().readFileAlloc(allocator, "input.txt", 10 * 1024 * 1024);
    defer allocator.free(contents);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var words = std.mem.split(u8, contents, "\n");
    var pq = PQlt.init(allocator, {});
    defer pq.deinit();

    var total: u32 = 0;
    var word: ?[]const u8 = words.first();
    while (word) |w| {
        if (w.len == 0) {
            try stdout.print("total: {d}\n", .{total});
            if (pq.peek()) |min| {
                if (total > min) {
                    if (pq.count() < 3) {
                        try pq.add(total);
                    } else try pq.update(min, total);
                }
            } else try pq.add(total);
            total = 0;
        } else {
            const calories = try std.fmt.parseUnsigned(u32, w, 10);
            total += calories;
        }

        word = words.next();
    }

    try stdout.print("max: {d}\n", .{pq.items[2]});

    try stdout.print("top3: {d}\n", .{sum(pq.items[0..3])});
    try bw.flush(); // don't forget to flush!
}

fn sum(numbers: []const u32) u32 {
    var result: u32 = 0;
    for (numbers) |x| {
        result += x;
    }
    return result;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
