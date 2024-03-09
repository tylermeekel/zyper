// Import std libraries
const std = @import("std");
const net = std.net;
const hash_map = std.hash_map;

// export libraries
pub const request = @import("request.zig");

/// HTTP Handler Function type
pub const HandlerFunction = *const fn (streamWriter: net.Stream.Writer, req: request.Request) anyerror!void;

const FunctionHashMap = hash_map.StringHashMap(HandlerFunction);

pub const HTTPServer = struct {
    port: u16,
    methodGetFunctions: FunctionHashMap,
    methodPostFunctions: FunctionHashMap,
    methodPutFunctions: FunctionHashMap,
    methodDeleteFunctions: FunctionHashMap,
    methodUpdateFunctions: FunctionHashMap,
    methodPatchFunctions: FunctionHashMap,

    pub fn init(allocator: std.mem.Allocator, port: u16) HTTPServer {
        return HTTPServer{
            .methodGetFunctions = FunctionHashMap.init(allocator),
            .methodPostFunctions = FunctionHashMap.init(allocator),
            .methodPutFunctions = FunctionHashMap.init(allocator),
            .methodDeleteFunctions = FunctionHashMap.init(allocator),
            .methodUpdateFunctions = FunctionHashMap.init(allocator),
            .methodPatchFunctions = FunctionHashMap.init(allocator),

            .port = port,
        };
    }

    pub fn start(self: HTTPServer, comptime buf_size: usize) !void {
        const address = try net.Address.parseIp("0.0.0.0", self.port);

        var server = try address.listen(.{});
        defer server.deinit();

        std.debug.print("Listening on :{d}\n", .{self.port});

        while (true) {
            // Accept connection
            var conn = try server.accept();
            defer conn.stream.close();

            var requestContent: [buf_size]u8 = undefined;

            const bytes_read = try conn.stream.reader().read(&requestContent);

            if (requestContent.len > 0) {
                const req: request.RequestData = request.RequestData{
                    .content = &requestContent,
                    .len = bytes_read,
                };

                const parsedRequest = request.parseRequest(req);

                var handlerFunc: HandlerFunction = undefined;

                switch (parsedRequest.method) {
                    .Get => {
                        handlerFunc = self.methodGetFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Patch => {
                        handlerFunc = self.methodPatchFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Post => {
                        handlerFunc = self.methodPostFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Put => {
                        handlerFunc = self.methodPutFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Update => {
                        handlerFunc = self.methodUpdateFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Delete => {
                        handlerFunc = self.methodDeleteFunctions.get(parsedRequest.path) orelse write404;
                    },
                    .Unknown => {
                        handlerFunc = write404;
                    },
                }
                
                handlerFunc(conn.stream.writer(), parsedRequest) catch {
                    conn.stream.writer().print("HTTP/1.1 500 Internal Server Error\r\n", .{}) catch {
                        //TODO: something
                        std.debug.print("Doing something!", .{});
                    };
                };
            }
        }
    }

    pub fn get(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodGetFunctions.put(path, handlerFunc);
    }

    pub fn post(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodPostFunctions.put(path, handlerFunc);
    }

    fn write404(streamWriter: net.Stream.Writer, _: request.Request) !void {
        streamWriter.print("HTTP/1.1 404 Not Found\r\n", .{}) catch {
            std.debug.print("Unable to write 404?", .{});
        };
    }
};
