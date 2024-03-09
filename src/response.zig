const std = @import("std");
const net = std.net;

pub const StatusCode = enum(u16) {
    // information responses
    continueStatus = 100,
    switchingProtocols = 101,
    processing = 102,
    earlyHints = 103,

    // successful responses
    ok = 200,
    created = 201,
    accepted = 202,
    nonAuthoritativeInformation = 203,
    noContent = 204,
    resetContent = 205,
    partialContent = 206,
    multiStatus = 207,
    alreadyReported = 208,
    imUsed = 226,

    // redirection messages
    multipleChoices = 300,
    movedPermanently = 301,
    found = 302,
    seeOther = 303,
    notModified = 304,
    temporaryRedirect = 307,
    permanentRedirect = 308,

    // client error responses
    badRequest = 400,
    unauthorized = 401,
    paymentRequired = 402,
    forbidden = 403,
    notFound = 404,
    methodNotAllowed = 405,
    notAcceptable = 406,
    proxyAuthenticationRequired = 407,
    requestTimeout = 408,
    conflict = 409,
    gone = 410,
    lengthRequired = 411,
    preconditionFailed = 412,
    payloadTooLarge = 413,
    uriTooLong = 414,
    unsupportedMediaType = 415,
    rangeNotSatisfiable = 416,
    expectationFailed = 417,
    imATeapot = 418,
    misdirectedRequest = 421,
    unprocessableContent = 422,
    locked = 423,
    failedDependency = 424,
    tooEarly = 425,
    upgradeRequired = 426,
    preconditionRequired = 428,
    tooManyRequests = 429,
    requestHeaderFieldsTooLarge = 431,
    unavailableForLegalReasons = 451,

    // server error responses
    internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505,
    variantAlsoNegotiates = 506,
    insufficientStorage = 507,
    loopDetected = 508,
    notExtended = 510,
    networkAuthenticationRequired = 511,

    // Super fun!
    pub fn toString(self: StatusCode) []const u8 {
        return switch (self) {
            .continueStatus => "Continue",
            .switchingProtocols => "Switching Protocols",
            .processing => "Processing",
            .earlyHints => "Early Hints",
            .ok => "OK",
            .created => "Created",
            .accepted => "Accepted",
            .nonAuthoritativeInformation => "Non-Authoritative Information",
            .noContent => "No Content",
            .resetContent => "Reset Content",
            .partialContent => "Partial Content",
            .multiStatus => "Multi-Status",
            .alreadyReported => "Already Reported",
            .imUsed => "IM Used",
            .multipleChoices => "Multiple Choices",
            .movedPermanently => "Moved Permanently",
            .found => "Found",
            .seeOther => "See Other",
            .notModified => "Not Modified",
            .temporaryRedirect => "Temporary Redirect",
            .permanentRedirect => "Permanent Redirect",
            .badRequest => "Bad Request",
            .unauthorized => "Unauthorized",
            .paymentRequired => "Payment Required",
            .forbidden => "Forbidden",
            .notFound => "Not Found",
            .methodNotAllowed => "Method Not Allowed",
            .notAcceptable => "Not Acceptable",
            .proxyAuthenticationRequired => "Proxy Authentication Required",
            .requestTimeout => "Request Timeout",
            .conflict => "Conflict",
            .gone => "Gone",
            .lengthRequired => "Length Required",
            .preconditionFailed => "Precondition Failed",
            .payloadTooLarge => "Payload Too Large",
            .uriTooLong => "URI Too Long",
            .unsupportedMediaType => "Unsupported Media Type",
            .rangeNotSatisfiable => "Range Not Satisfiable",
            .expectationFailed => "Expectation Failed",
            .imATeapot => "I'm a teapot",
            .misdirectedRequest => "Misdirected Request",
            .unprocessableContent => "Unprocessable Content",
            .locked => "Locked",
            .failedDependency => "Failed Dependency",
            .tooEarly => "Too Early",
            .upgradeRequired => "Upgrade Required",
            .preconditionRequired => "Precondition Required",
            .tooManyRequests => "Too Many Requests",
            .requestHeaderFieldsTooLarge => "Request Header Fields Too Large",
            .unavailableForLegalReasons => "Unavailable For Legal Reasons",
            .internalServerError => "Internal Server Error",
            .notImplemented => "Not Implemented",
            .badGateway => "Bad Gateway",
            .serviceUnavailable => "Service Unavailable",
            .gatewayTimeout => "Gateway Timeout",
            .httpVersionNotSupported => "HTTP Version Not Supported",
            .variantAlsoNegotiates => "Variant Also Negotiates",
            .insufficientStorage => "Insufficient Storage",
            .loopDetected => "Loop Detected",
            .notExtended => "Not Extended",
            .networkAuthenticationRequired => "Network Authentication Required",
        };
    }
};

/// Struct to help build a response to the client
pub const Response = struct {
    code: StatusCode = StatusCode.ok,
    body: []const u8,
    headers: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator, code: StatusCode, body: []const u8) Response {
        return Response{
            .code = code,
            .body = body,
            .headers = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: Response) void {
        self.headers.deinit();
    }

    /// Convert Response data to properly formatted HTTP Response
    pub fn toString(self: Response, allocator: std.mem.Allocator) ![]u8 {
        const formatString = "HTTP/1.1 {d} {s}\r\n{s}\r\n{s}"
        // \\HTTP/1.1 {d} {s}{s}
        // \\{s}
        // \\{s}
        ;

        var headersString = std.ArrayList(u8).init(allocator);
        for (self.headers.items) |header| {
            try headersString.appendSlice(header);
            try headersString.appendSlice("\r\n");
        }
        defer headersString.deinit();

        const contentLengthHeader = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n", .{self.body.len});
        defer allocator.free(contentLengthHeader);

        try headersString.appendSlice(contentLengthHeader);

        return try std.fmt.allocPrint(allocator, formatString, .{ @as(u32, @intFromEnum(self.code)), self.code.toString(), headersString.items, self.body });
    }

    pub fn addHeader(self: *Response, allocator: std.mem.Allocator, headerName: []const u8, headerValue: []const u8) !void {
        const header = try std.fmt.allocPrint(allocator, "{s}: {s}", .{ headerName, headerValue });

        try self.headers.append(header);
    }
};

test "response tostring" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const resp = Response.init(allocator, StatusCode.ok, "Hello, World!");
    defer resp.deinit();

    const expectedResponse = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, World!";

    const responseString = try resp.toString(allocator);
    defer allocator.free(responseString);

    try std.testing.expectEqualStrings(expectedResponse, responseString);
}

test "add header" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var resp = Response.init(allocator, StatusCode.ok, "Hello, World!");
    defer resp.deinit();

    try resp.addHeader(allocator, "Test-Header", "Test-Value");

    const expectedResponse = "HTTP/1.1 200 OK\r\nTest-Header: Test-Value\r\nContent-Length: 13\r\n\r\nHello, World!";

    const responseString = try resp.toString(allocator);
    defer allocator.free(responseString);

    try std.testing.expectEqualStrings(expectedResponse, responseString);
}
