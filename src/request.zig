const std = @import("std");

pub const RequestData = struct {
    content: []u8,
    len: usize,
};

pub const Method = enum {
    Get,
    Post,
    Delete,
    Patch,
    Put,
    Unknown,
};

const HeaderHashMap = std.hash_map.StringHashMap([]const u8);

pub const Request = struct {
    method: Method,
    path: []const u8,
    headers: HeaderHashMap,
    body: []const u8,
};

pub fn parseRequest(request: RequestData) Request {
    var topAndBody = std.mem.splitSequence(u8, request.content, "\r\n\r\n");

    const top = topAndBody.first();
    const body = topAndBody.rest()[0 .. request.len - top.len - 4];

    // split top
    var topSplit = std.mem.splitSequence(u8, top, "\r\n");
    const requestLine = topSplit.first();

    // Split requestline
    var requestLineSplit = std.mem.splitSequence(u8, requestLine, " ");

    // Get method and path from request
    const methodString = requestLineSplit.first();
    const path = requestLineSplit.next() orelse "";

    // Create allocator for header hash map
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var headers = HeaderHashMap.init(allocator);

    // read each header line and add to header hashmap
    while (topSplit.next()) |headerLine| {
        var headerSplit = std.mem.splitSequence(u8, headerLine, ": ");
        const headerName = headerSplit.first();
        const headerContent = headerSplit.next() orelse "";

        headers.put(headerName, headerContent) catch {
            std.debug.print("out of memory!", .{});
        };
    }

    // return the parsed request
    return Request{
        .path = path,
        .method = parseMethod(methodString),
        .headers = headers,
        .body = body,
    };
}

pub fn parseMethod(methodStr: []const u8) Method {
    if (std.mem.eql(u8, methodStr, "GET")) {
        return Method.Get;
    } else if (std.mem.eql(u8, methodStr, "POST")) {
        return Method.Post;
    } else if (std.mem.eql(u8, methodStr, "PATCH")) {
        return Method.Patch;
    } else if (std.mem.eql(u8, methodStr, "PUT")) {
        return Method.Put;
    } else if (std.mem.eql(u8, methodStr, "DELETE")) {
        return Method.Delete;
    } else {
        return Method.Unknown;
    }
}
