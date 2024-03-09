const std = @import("std");
const zyper = @import("root.zig");

// This file serves as a quick example for how to use the Zyper library

pub fn main() !void {

    // We allow users to handle their memory on their own, and use their own preferred allocation strategy.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        std.debug.print("Deinit alloc", .{});
        if (deinit_status == std.heap.Check.leak) {
            std.debug.print("Leaks detected", .{});
        }
    }

    // Create the HTTPServer struct, passing in your allocator and port to run the server on.
    var httpServer = zyper.HTTPServer.init(allocator, 3000);
    
    // Each request type is held as a hash map, we expose these to allow users to free this memory
    // as they please. In the future, this will be possible with one method.
    defer httpServer.methodDeleteFunctions.deinit();
    defer httpServer.methodGetFunctions.deinit();
    defer httpServer.methodPostFunctions.deinit();
    defer httpServer.methodPutFunctions.deinit();
    defer httpServer.methodPatchFunctions.deinit();

    // We attach a POST handler function to the /echo path
    try httpServer.post("/echo", yippeeHandler);

    // Start the server, passing in a buffer size for reading requests to the server.
    // In the future this will be handled automatically.
    try httpServer.start(4096);
}

// Create a function handler for POST requests.
// These functions must follow the signature:
// fn(w: std.net.Stream.Writer, r: zyper.request.Request) anyerror!void
fn yippeeHandler(w: std.net.Stream.Writer, _: zyper.request.Request) !void {
    var gpa = std.heap.GeneralPurposeAllocator(){};
    const allocator = gpa.allocator();

    const response = zyper.response.Response.init(allocator, zyper.response.StatusCode.ok, "Yippee!");
    defer response.deinit();

    const responseString = try response.toString(allocator);
    w.write(responseString);
    defer allocator.free(responseString);
}