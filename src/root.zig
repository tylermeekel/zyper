// Import std libraries
const std = @import("std");
const net = std.net;
const hash_map = std.hash_map;

// export libraries
pub const request = @import("request.zig");
pub const response = @import("response.zig");

/// HTTP Handler Function type
pub const HandlerFunction = *const fn (streamWriter: net.Stream.Writer, req: request.Request) anyerror!void;

/// HashMap type for matching paths to HandlerFunctions
const HandlerFunctionHashMap = hash_map.StringHashMap(HandlerFunction);

pub const HTTPServer = struct {
    port: u16,
    methodGetFunctions: HandlerFunctionHashMap,
    methodPostFunctions: HandlerFunctionHashMap,
    methodPutFunctions: HandlerFunctionHashMap,
    methodDeleteFunctions: HandlerFunctionHashMap,
    methodPatchFunctions: HandlerFunctionHashMap,
    notFoundFunc: HandlerFunction,

    /// Initialize an HTTPServer struct. This allocates space for each of the handler function
    /// hashmaps.
    pub fn init(allocator: std.mem.Allocator, port: u16) HTTPServer {
        return HTTPServer{
            .methodGetFunctions = HandlerFunctionHashMap.init(allocator),
            .methodPostFunctions = HandlerFunctionHashMap.init(allocator),
            .methodPutFunctions = HandlerFunctionHashMap.init(allocator),
            .methodDeleteFunctions = HandlerFunctionHashMap.init(allocator),
            .methodPatchFunctions = HandlerFunctionHashMap.init(allocator),

            .notFoundFunc = write404,

            .port = port,
        };
    }

    /// Start the server. Reads connections and assigns them to the appropriate HandlerFunction.
    /// This is currently single-threaded.
    pub fn start(self: HTTPServer, comptime buf_size: usize) !void {

        // Parse an address on the given port.
        const address = try net.Address.parseIp("0.0.0.0", self.port);

        // Begin listening on the parsed address.
        var server = try address.listen(.{});
        defer server.deinit();

        // Print listening message
        std.debug.print("Listening on :{d}\n", .{self.port});

        // Loop forever
        while (true) {
            // Accept connection
            var conn = try server.accept();
            defer conn.stream.close();

            // Create buffer to hold request content
            var requestContent: [buf_size]u8 = undefined;

            // read the connection into the buffer
            const bytes_read = try conn.stream.reader().read(&requestContent);

            // make sure the request content has information
            if (requestContent.len > 0) {

                // Create RequestData struct from request content and number of bytes read
                const req: request.RequestData = request.RequestData{
                    .content = &requestContent,
                    .len = bytes_read,
                };

                // Parse the request data into a Request struct
                const parsedRequest = request.parseRequest(req);

                // create undefined handler func to assign to
                var handlerFunc: HandlerFunction = undefined;

                // switch based on the method of the Request struct
                switch (parsedRequest.method) {
                    .get => {
                        // Get the GET HandlerFunc on the Reques path if it exists, 
                        // or replace it with the write404 HandlerFunc
                        handlerFunc = self.methodGetFunctions.get(parsedRequest.path) orelse self.notFoundFunc;
                    },
                    .patch => {
                        handlerFunc = self.methodPatchFunctions.get(parsedRequest.path) orelse self.notFoundFunc;
                    },
                    .post => {
                        handlerFunc = self.methodPostFunctions.get(parsedRequest.path) orelse self.notFoundFunc;
                    },
                    .put => {
                        handlerFunc = self.methodPutFunctions.get(parsedRequest.path) orelse self.notFoundFunc;
                    },
                    .delete => {
                        handlerFunc = self.methodDeleteFunctions.get(parsedRequest.path) orelse self.notFoundFunc;
                    },
                    .unknown => {
                        handlerFunc = self.notFoundFunc;
                    },
                }
                
                // Call the handler func, send internal server error if it errors.
                handlerFunc(conn.stream.writer(), parsedRequest) catch {
                    conn.stream.writer().print("HTTP/1.1 500 Internal Server Error\r\n", .{}) catch {
                        //TODO: something
                        std.debug.print("Doing something!", .{});
                    };
                };
            }
        }
    }

    /// Assign a GET HandlerFunc to the given path.
    pub fn get(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodGetFunctions.put(path, handlerFunc);
    }

    /// Assign a POST HandlerFunc to the given path.
    pub fn post(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodPostFunctions.put(path, handlerFunc);
    }

    /// Assign a PATCH HandlerFunc to the given path.
    pub fn patch(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodPatchFunctions.put(path, handlerFunc);
    }

    /// Assign a PUT HandlerFunc to the given path.
    pub fn put(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodPutFunctions.put(path, handlerFunc);
    }

    /// Assign a DELETE HandlerFunc to the given path.
    pub fn delete(self: *HTTPServer, path: []const u8, handlerFunc: HandlerFunction) !void {
        try self.methodDeleteFunctions.put(path, handlerFunc);
    }

    /// 404 handler.
    fn write404(streamWriter: net.Stream.Writer, _: request.Request) !void {
        // TODO: Make more extravagant, make user be able to change this
        streamWriter.print("HTTP/1.1 404 Not Found\r\n", .{}) catch {
            std.debug.print("Unable to write 404?", .{});
        };
    }
};
