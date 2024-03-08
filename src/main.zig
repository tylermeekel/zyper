const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == std.heap.Check.leak) {
            std.debug.print("Leaks detected", .{});
        }
    }

    var httpServer = root.HTTPServer.init(allocator, 1234);

    try httpServer.get("/", getSomethingHandler);

    try httpServer.start();
}

fn getSomethingHandler(w: std.net.Stream.Writer, r: std.net.Stream.Reader) void {
    _ = w;
    _ = r;
    std.debug.print("YOO", .{});
}

