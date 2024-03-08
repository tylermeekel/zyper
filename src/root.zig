// Import std libraries
const std = @import("std");
const net = std.net;
const hash_map = std.hash_map;

/// HTTP Handler Function type
pub const HandlerFunction = *const fn (streamWriter: net.Stream.Writer, streamReader: net.Stream.Reader) void;

const FunctionHashMap = hash_map.StringHashMap(HandlerFunction);

pub const Request = struct {
    path: []const u8,
    body: []u8,
};

pub const HTTPServer = struct {
    port: u16,
    methodGetFunctions: FunctionHashMap,
    methodPostFunctions: FunctionHashMap,
    methodPutFunctions: FunctionHashMap ,
    methodDeleteFunctions: FunctionHashMap ,

    pub fn init(allocator: std.mem.Allocator, port: u16) HTTPServer {
        return HTTPServer{
            .methodGetFunctions = FunctionHashMap.init(allocator),
            .methodPostFunctions = FunctionHashMap.init(allocator),
            .methodPutFunctions = FunctionHashMap.init(allocator),
            .methodDeleteFunctions = FunctionHashMap.init(allocator),

            .port = port,
        };
    }

    pub fn start(self: HTTPServer) !void {
        const address = try net.Address.parseIp("0.0.0.0", self.port);
        var server = try address.listen(.{});
        std.debug.print("Listening on :{d}", .{self.port});

        while (true) {
            var conn = try server.accept();
            var body: [1024]u8 = undefined;

            const bytes_read = try conn.stream.read(&body);
            if (bytes_read > 0) {
                std.debug.print("{s}", .{body[0..bytes_read]});
            }
        }
    }

    pub fn get(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodGetFunctions.put(path, handlerFunc);
    }
};
