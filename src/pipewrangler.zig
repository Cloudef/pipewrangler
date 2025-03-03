const std = @import("std");
const build_options = @import("build_options");

const root = @import("root");
pub const options: Options = if (@hasDecl(root, "pipewrangler_options")) root.pipewrangler_options else .{};

pub const Options = struct {
    /// Enable debug logs and tracing.
    debug: bool = build_options.debug,
};

pub const wire = @import("wire.zig");
pub const ReadError = wire.ReadError;
pub const WriteError = wire.WriteError;

pub const Connection = struct {
    stream: std.net.Stream,
    sent_seq: u32 = 0,
    recv_seq: u32 = 0,
    registry_generation: u64 = 0,
    dirty_generation: bool = false,

    pub const InitFdError = error{FcntlFailed};

    pub fn initFd(fd: std.posix.fd_t) InitFdError!@This() {
        try setNonBlock(fd, true);
        return .{ .stream = .{ .handle = fd } };
    }

    pub const InitError = error{NotFound} || InitFdError;

    pub fn init() InitError!@This() {
        return initFd(try open("pipewire-0"));
    }

    fn open(socket_name: []const u8) !std.posix.fd_t {
        var buffer: [std.fs.max_path_bytes]u8 = undefined;
        var fba: std.heap.FixedBufferAllocator = .init(&buffer);
        const paths: []const []const u8 = &.{
            "PIPEWIRE_RUNTIME_DIR",
            "XDG_RUNTIME_DIR",
            "USERPROFILE",
        };
        for (paths) |env| {
            if (std.posix.getenv(env)) |val| {
                const path = std.fs.path.join(fba.allocator(), &.{ val, socket_name }) catch continue;
                defer fba.reset();
                const stream = std.net.connectUnixSocket(path) catch continue;
                debug("found pipewire socket at: {s}", .{path});
                return stream.handle;
            }
        }
        return error.NotFound;
    }

    pub fn deinit(self: *@This(), close: enum { close, keep_alive }) void {
        if (close == .close) self.stream.close();
        self.* = undefined;
    }

    pub fn write(self: *@This(), comptime ext: wire.Extension, id: wire.Id, comptime method: ext.Schema().Method, args: ext.Schema().MethodArgs(method)) WriteError!void {
        debug("-> {s}::{s} {s} ~ {}", .{ @tagName(ext), @tagName(method), std.json.fmt(args, .{}), self.sent_seq });
        var footers: std.BoundedArray(wire.ClientFooter, 1) = .{};
        if (self.dirty_generation) {
            footers.append(.{ .generation = .{ .client_generation = self.registry_generation } }) catch unreachable;
            self.dirty_generation = false;
        }
        try ext.write(id, method, self.sent_seq, args, .{
            .footers = footers.constSlice(),
        }, self.stream.writer());
        self.sent_seq += 1;
    }

    pub fn read(self: *@This(), handler: anytype) ReadError!void {
        const Handler = @TypeOf(handler.*);
        comptime {
            if (!@hasDecl(Handler, "extensions")) {
                @compileError("handler must have a `pub const extensions: []const pw.wire.Extension` specifying the extensions it implements");
            }
            for (Handler.extensions) |ext| {
                for (std.enums.values(ext.Schema().Event)) |ev| {
                    const sig = std.fmt.comptimePrint("{s}::{s}", .{ @tagName(ext), @tagName(ev) });
                    const ext_name = toPascalCaseComptime(@tagName(ext));
                    const ev_name = toPascalCaseComptime(@tagName(ev));
                    const arg_name = if (std.mem.eql(u8, @tagName(ev), "error")) "err" else @tagName(ev);
                    const err = std.fmt.comptimePrint("handler is missing a implementation for `pub fn @\"{s}\"(self: *@This(), id: pw.wire.Id, {s}: pw.wire.{s}.{s}) !void`", .{ sig, arg_name, ext_name, ev_name });
                    if (!@hasDecl(Handler, sig)) {
                        @compileError(err);
                    } else {
                        const args = std.meta.ArgsTuple(@TypeOf(@field(Handler, sig)));
                        if (args != struct { @TypeOf(handler), wire.Id, ext.Schema().EventArgs(ev) }) {
                            @compileError(err);
                        }
                    }
                }
            }
        }

        const header = try wire.Header.init(self.stream.reader());
        self.recv_seq = @max(self.recv_seq, header.seq);

        var buffer: [std.math.maxInt(u16)]u8 = undefined;
        var fba: std.heap.FixedBufferAllocator = .init(&buffer);
        const arena = fba.allocator();

        var counter = std.io.countingReader(self.stream.reader());
        const payload = try header.readPod(arena, counter.reader());

        if (header.msg.size > counter.bytes_read) {
            var footer = try header.readFooter(arena, counter.reader());
            while (try footer.next()) |fp| switch (fp) {
                .generation => |data| {
                    self.registry_generation = data.registry_generation;
                    self.dirty_generation = true;
                },
            };
        }

        std.debug.assert(header.msg.size >= counter.bytes_read);
        try self.stream.reader().skipBytes(header.msg.size - counter.bytes_read, .{});

        const ext = handler.@"pw::ext"(header.id) orelse {
            debug("<- (unknown id: {})", .{header.id});
            return;
        };

        switch (ext) {
            inline else => |tag| {
                const Schema = tag.Schema();
                if (std.meta.fields(Schema.Event).len > 0) {
                    const event: Schema.Event = @enumFromInt(header.msg.opcode);
                    switch (event) {
                        inline else => |ev| {
                            const sig = std.fmt.comptimePrint("{s}::{s}", .{ @tagName(tag), @tagName(ev) });
                            if (@hasDecl(Handler, sig)) {
                                debug("<- {s} ~ {} ~ {}", .{ sig, header.id, header.seq });
                                debug("{}", .{payload});
                                const args = try payload.map(Schema.EventArgs(ev));
                                @call(.auto, @field(Handler, sig), .{ handler, header.id, args }) catch |err| {
                                    debug("-!- {}", .{err});
                                    // TODO: pass error to server
                                };
                            } else {
                                debug("<- {s} ~ {} ~ {} (unimplemented)", .{ sig, header.id, header.seq });
                                debug("{}", .{payload});
                            }
                        },
                    }
                } else {
                    debug("<- {s} ~ {} (unknown event: {})", .{ @tagName(tag), header.seq, header.msg.opcode });
                }
            },
        }
    }

    pub fn readAll(self: *@This(), handler: anytype) ReadError!void {
        var got_one: bool = false;
        while (true) {
            self.read(handler) catch |err| switch (err) {
                error.WouldBlock => if (got_one) break else continue,
                else => |e| return e,
            };
            got_one = true;
        }
    }
};

fn toPascalCase(allocator: std.mem.Allocator, snake_case: []const u8) ![]const u8 {
    var result: std.ArrayListUnmanaged(u8) = try .initCapacity(allocator, snake_case.len);
    errdefer result.deinit(allocator);
    var it = std.mem.tokenizeAny(u8, snake_case, "_");
    while (it.next()) |word| {
        if (word.len == 0) continue;
        var first = word[0];
        if (std.ascii.isLower(first)) first = std.ascii.toUpper(first);
        try result.append(allocator, first);
        try result.appendSlice(allocator, word[1..]);
    }
    return result.toOwnedSlice(allocator);
}

fn toPascalCaseComptime(comptime snake_case: []const u8) []const u8 {
    var buffer: [snake_case.len]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buffer);
    return toPascalCase(fba.allocator(), snake_case) catch unreachable;
}

fn setNonBlock(fd: std.posix.fd_t, blocking: bool) error{FcntlFailed}!void {
    const NONBLOCK: u32 = 1 << @bitOffsetOf(std.posix.O, "NONBLOCK");
    const flags = std.posix.fcntl(fd, std.posix.F.GETFL, 0) catch return error.FcntlFailed;
    if (blocking) {
        _ = std.posix.fcntl(fd, std.posix.F.SETFL, flags | NONBLOCK) catch return error.FcntlFailed;
    } else {
        _ = std.posix.fcntl(fd, std.posix.F.SETFL, flags & ~NONBLOCK) catch return error.FcntlFailed;
    }
}

fn debug(comptime fmt: []const u8, args: anytype) void {
    if (!options.debug) return;
    const log = std.log.scoped(.pipewrangler);
    log.debug(fmt, args);
}
