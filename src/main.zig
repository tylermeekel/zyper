const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        std.debug.print("Deinit alloc", .{});
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == std.heap.Check.leak) {
            std.debug.print("Leaks detected", .{});
        }
    }

    var httpServer = root.HTTPServer.init(allocator, 3000);
    // TODO: Make this happen in one function
    defer httpServer.methodDeleteFunctions.deinit();
    defer httpServer.methodGetFunctions.deinit();
    defer httpServer.methodPostFunctions.deinit();
    defer httpServer.methodPutFunctions.deinit();
    defer httpServer.methodPatchFunctions.deinit();
    defer httpServer.methodUpdateFunctions.deinit();

    try httpServer.post("/echo", echoHandler);

    try httpServer.start(4096);
}

fn echoHandler(w: std.net.Stream.Writer, r: root.request.Request) !void {
    try w.print("HTTP/1.1 200 OK\r\nContent-Length: {d}\r\n\r\n{s}", .{ r.body.len, r.body });
}