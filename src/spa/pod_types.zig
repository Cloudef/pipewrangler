const std = @import("std");
const spa = @import("spa.zig");
const Pod = @import("pod.zig").Pod;

pub const Header = extern struct {
    size: u32,
    type: Pod.Type,

    pub fn read(reader: anytype) !@This() {
        var header: @This() = undefined;
        _ = try reader.readAll(std.mem.asBytes(&header));
        if (@intFromEnum(header.type) < @intFromEnum(Pod.Type.none)) return error.InvalidPodHeader;
        if (@intFromEnum(header.type) > @intFromEnum(Pod.Type.choice)) return error.InvalidPodHeader;
        return header;
    }
};

pub const None = struct {
    pub fn read(_: std.mem.Allocator, size: u32, _: anytype) !@This() {
        if (size != 0) return error.InvalidNone;
        return .{};
    }

    pub fn write(_: void, writer: anytype) !void {
        const header: Header = .{ .type = .none, .size = 0 };
        try writer.writeAll(std.mem.asBytes(&header));
    }

    pub fn writeSelf(_: @This(), writer: anytype) !void {
        return write({}, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .void => {},
            .optional => null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(_: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("None");
    }

    pub fn jsonStringify(_: @This(), jws: anytype) !void {
        try jws.write(null);
    }
};

pub const Bool = enum(u1) {
    false,
    true,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 4) return error.InvalidBool;
        var val: u32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 4) return error.InvalidBool;
        return if (val > 0) .true else .false;
    }

    pub fn write(val: bool, writer: anytype) !void {
        var int: packed struct(u64) {
            val: u32,
            padding: u32 = 0,
        } = .{ .val = @intFromBool(val) };
        const header: Header = .{ .type = .bool, .size = 4 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&int));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self == .true, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .bool => self == .true,
            .int => @intFromBool(self == .true),
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll(@tagName(self));
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(self == .true);
    }
};

pub const Id = enum(u32) {
    _,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 4) return error.InvalidId;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 4) return error.InvalidId;
        return val;
    }

    pub fn write(val: anytype, writer: anytype) !void {
        var int: packed struct(u64) {
            val: u32,
            padding: u32 = 0,
        } = .{ .val = @intFromEnum(val) };
        const header: Header = .{ .type = .id, .size = 4 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&int));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"enum" => std.meta.intToEnum(T, @intFromEnum(self)) catch error.IncompatibleDestinationType,
            .int => std.math.cast(T, @intFromEnum(self)) orelse error.IncompatibleDestinationType,
            .@"struct" => |ti| switch (ti.layout) {
                .@"packed" => @bitCast(std.math.cast(ti.backing_integer.?, @intFromEnum(self)) orelse return error.IncompatibleDestinationType),
                else => error.IncompatibleDestinationType,
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const val: u32 = @intFromEnum(self);
        try writer.print("Id:{}", .{val});
    }
};

pub const Int = enum(i32) {
    _,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 4) return error.InvalidInt;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 4) return error.InvalidInt;
        return val;
    }

    pub fn write(val: u32, writer: anytype) !void {
        var int: packed struct(u64) {
            val: u32,
            padding: u32 = 0,
        } = .{ .val = val };
        const header: Header = .{ .type = .int, .size = 4 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&int));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(@bitCast(@intFromEnum(self)), writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"enum" => std.meta.intToEnum(T, @intFromEnum(self)) catch error.IncompatibleDestinationType,
            .int => std.math.cast(T, @intFromEnum(self)) orelse error.IncompatibleDestinationType,
            .@"struct" => |ti| switch (ti.layout) {
                .@"packed" => @bitCast(std.math.cast(ti.backing_integer.?, @intFromEnum(self)) orelse return error.IncompatibleDestinationType),
                else => error.IncompatibleDestinationType,
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const val: i32 = @intFromEnum(self);
        try writer.print("Int:{}", .{val});
    }
};

pub const Long = enum(i64) {
    _,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidLong;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidLong;
        return val;
    }

    pub fn write(val: u64, writer: anytype) !void {
        const header: Header = .{ .type = .long, .size = 8 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&val));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(@bitCast(@intFromEnum(self)), writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"enum" => std.meta.intToEnum(T, @intFromEnum(self)) catch error.IncompatibleDestinationType,
            .int => std.math.cast(T, @intFromEnum(self)) orelse error.IncompatibleDestinationType,
            .@"struct" => |ti| switch (ti.layout) {
                .@"packed" => @bitCast(std.math.cast(ti.backing_integer.?, @intFromEnum(self)) orelse return error.IncompatibleDestinationType),
                else => error.IncompatibleDestinationType,
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const val: i64 = @intFromEnum(self);
        try writer.print("Long:{}", .{val});
    }
};

pub const Float = struct {
    value: f32,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 4) return error.InvalidFloat;
        var val: f32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 4) return error.InvalidFloat;
        return .{ .value = val };
    }

    pub fn write(val: f32, writer: anytype) !void {
        var int: packed struct(u64) {
            val: f32,
            padding: u32 = 0,
        } = .{ .val = val };
        const header: Header = .{ .type = .id, .size = 4 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&int));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self.value, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .float => @floatCast(self.value),
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Float:{}", .{self.value});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(self.value);
    }
};

pub const Double = struct {
    value: f64,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidDouble;
        var val: f64 = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidDouble;
        return .{ .value = val };
    }

    pub fn write(val: f64, writer: anytype) !void {
        const header: Header = .{ .type = .double, .size = 8 };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&val));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self.value, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .float => @floatCast(self.value),
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Double:{}", .{self.value});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(self.value);
    }
};

pub const String = struct {
    slice: [:0]const u8,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size <= 0) return error.InvalidString;
        var buf = try arena.alloc(u8, size);
        errdefer arena.free(buf);
        if (try reader.readAll(buf[0..]) != size) return error.InvalidString;
        if (buf[size - 1] != 0) return error.InvalidString;
        return .{ .slice = buf[0 .. size - 1 :0] };
    }

    pub fn write(val: [:0]const u8, writer: anytype) !void {
        const len = val.len + 1;
        const header: Header = .{ .type = .string, .size = @intCast(len) };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(val[0..len]);
        try writer.writeByteNTimes(0, std.mem.alignForward(usize, len, 8) - len);
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self.slice, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .bool => std.mem.eql(u8, self.slice, "true"),
            .int => std.fmt.parseInt(T, self.slice, 10) catch error.IncompatibleDestinationType,
            .float => std.fmt.parseFloat(T, self.slice) catch error.IncompatibleDestinationType,
            .@"enum" => |ti| switch (ti.is_exhaustive) {
                true => std.meta.stringToEnum(T, self.slice) orelse error.IncompatibleDestinationType,
                false => std.meta.intToEnum(T, std.fmt.parseInt(ti.tag_type, self.slice, 10) catch return error.IncompatibleDestinationType) catch error.IncompatibleDestinationType,
            },
            .pointer => |ti| switch (ti.size) {
                .slice => switch (ti.child) {
                    u8 => self.slice,
                    else => error.IncompatibleDestinationType,
                },
                else => error.IncompatibleDestinationType,
            },
            .array => |ti| switch (ti.child) {
                u8 => D: {
                    if (self.slice.len < ti.len) break :D error.IncompatibleDestinationType;
                    break :D self.slice[0..ti.len].*;
                },
                else => error.IncompatibleDestinationType,
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("\"{s}\"", .{self.slice});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.write(self.slice);
    }
};

pub const Bytes = struct {
    slice: []const u8,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var buf = try arena.alloc(u8, size);
        errdefer arena.free(buf);
        if (try reader.readAll(buf[0..]) != size) return error.InvalidBytes;
        return .{ .slice = buf };
    }

    pub fn write(val: []const u8, writer: anytype) !void {
        const header: Header = .{ .type = .string, .size = @intCast(val.len) };
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(val[0..]);
        try writer.writeByteNTimes(0, std.mem.alignForward(usize, val.len, 8) - val.len);
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self.slice, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .bool, .int, .float => std.mem.bytesToValue(T, self.slice),
            .@"enum" => |ti| std.meta.intToEnum(T, std.mem.bytesToValue(ti.tag_type, self.slice)) catch error.IncompatibleDestinationType,
            .pointer => |ti| switch (ti.size) {
                .slice => switch (ti.child) {
                    u8 => if (ti.sentinel()) |_| error.IncompatibleDestinationType else self.slice,
                    else => error.IncompatibleDestinationType,
                },
                else => error.IncompatibleDestinationType,
            },
            .array => |ti| switch (ti.child) {
                u8 => if (self.slice.len >= ti.len) self.slice[0..ti.len].* else error.IncompatibleDestinationType,
                else => error.IncompatibleDestinationType,
            },
            .@"struct" => |ti| switch (ti.layout) {
                .@"packed", .@"extern" => std.mem.bytesToValue(T, self.slice),
                else => error.IncompatibleDestinationType,
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Bytes:{x}", .{self.slice});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginWriteRaw();
        _ = try jws.stream.write("\"");
        var encoder = std.base64.standard_no_pad.Encoder;
        try encoder.encodeWriter(jws.stream, self.slice);
        _ = try jws.stream.write("\"");
        jws.endWriteRaw();
    }
};

pub const Rectangle = extern struct {
    width: u32,
    height: u32,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidRectangle;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidRectangle;
        return val;
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        @panic("fixme");
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Rectangle:{},{}", .{ self.width, self.height });
    }
};

pub const Fraction = extern struct {
    num: u32,
    denom: u32,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidFraction;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidFraction;
        return val;
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        @panic("fixme");
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Fraction:{}/{}", .{ self.num, self.denom });
    }
};

pub const Bitmap = struct {
    bits: []const u8,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var buf = try arena.alloc(u8, size);
        errdefer arena.free(buf);
        if (try reader.readAll(buf[0..]) != size) return error.InvalidBitmap;
        return .{ .bits = buf };
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        @panic("fixme");
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Bitmap:{x}", .{self.bits});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginWriteRaw();
        _ = try jws.stream.write("\"");
        var encoder = std.base64.standard_no_pad.Encoder;
        try encoder.encodeWriter(jws.stream, self.bits);
        _ = try jws.stream.write("\"");
        jws.endWriteRaw();
    }
};

pub const Array = union(Pod.Type) {
    none: void,
    bool: []const Bool,
    id: []const Id,
    int: []const Int,
    long: []const Long,
    float: []const Float,
    double: []const Double,
    string: void,
    bytes: void,
    rectangle: []const Rectangle,
    fraction: []const Fraction,
    bitmap: void,
    array: void,
    @"struct": void,
    object: void,
    sequence: void,
    pointer: []const Pointer,
    fd: []const Fd,
    choice: void,
    pod: void,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var child_size: u32 = undefined;
        var child_type: u32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&child_size)) != 4) return error.InvalidArray;
        if (try reader.readAll(std.mem.asBytes(&child_type)) != 4) return error.InvalidArray;
        const array_size = size - 8;
        inline for (std.meta.fields(Pod.Type)) |field| {
            const Field = @FieldType(@This(), field.name);
            if (Field != void and field.value == child_type) {
                const Child = std.meta.Child(Field);
                const items = try arena.alloc(Child, array_size / child_size);
                errdefer arena.free(items);
                for (items) |*item| {
                    const pod: Pod = try .readType(arena, @enumFromInt(child_type), child_size, .dont_align, reader);
                    item.* = try pod.map(Child);
                }
                return @unionInit(@This(), field.name, items);
            }
        }
        return error.InvalidArray;
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        switch (self) {
            inline else => |items| {
                if (@TypeOf(items) == void) return error.IncompatibleDestinationType;
                const Child = std.meta.Child(@TypeOf(items));
                return switch (@typeInfo(T)) {
                    .pointer => |ti| D: {
                        if (@sizeOf(ti.child) != @sizeOf(Child)) break :D error.IncompatibleDestinationType;
                        break :D @ptrCast(items);
                    },
                    .array => |ti| D: {
                        if (@sizeOf(ti.child) != @sizeOf(Child)) break :D error.IncompatibleDestinationType;
                        if (items.len < ti.len) break :D error.IncompatibleDestinationType;
                        break :D @bitCast(items[0..ti.len].*);
                    },
                    else => error.IncompatibleDestinationType,
                };
            },
        }
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |items| {
                try writer.print("Array: {any}", .{items});
            },
        }
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        switch (self) {
            inline else => |items| {
                if (@TypeOf(items) == void) return;
                try jws.write(items);
            },
        }
    }
};

pub const Struct = struct {
    fields: []const Pod,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var buf = try arena.alloc(u8, size);
        errdefer arena.free(buf);
        if (try reader.readAll(buf[0..]) != size) return error.InvalidStruct;

        var pods: std.ArrayListUnmanaged(Pod) = .empty;
        errdefer pods.deinit(arena);

        var stream = std.io.fixedBufferStream(buf[0..]);
        while (stream.pos < size) {
            const field: Pod = try .read(arena, @intCast(size - stream.pos), stream.reader());
            try pods.append(arena, field);
        }

        return .{ .fields = try pods.toOwnedSlice(arena) };
    }

    pub fn write(val: anytype, writer: anytype) !void {
        switch (@typeInfo(@TypeOf(val))) {
            .@"struct" => |ti| {
                var counter = std.io.countingWriter(std.io.null_writer);
                inline for (ti.fields) |field| {
                    try Pod.write(@field(val, field.name), counter.writer());
                }
                const header: Header = .{
                    .type = .@"struct",
                    .size = @intCast(counter.bytes_written),
                };
                try writer.writeAll(std.mem.asBytes(&header));
                inline for (ti.fields) |field| {
                    try Pod.write(@field(val, field.name), writer);
                }
            },
            else => @compileError("can only write structs"),
        }
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        var counter = std.io.countingWriter(std.io.null_writer);
        for (self.fields) |field| try field.write(counter.writer());
        const header: Header = .{
            .type = .@"struct",
            .size = @intCast(counter.bytes_written),
        };
        try writer.writeAll(std.mem.asBytes(&header));
        for (self.fields) |field| try field.write(writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"struct" => |ti| D: {
                var st: T = undefined;
                inline for (ti.fields, 0..) |dst_field, idx| {
                    var src_field = &self.fields[idx];
                    @field(st, dst_field.name) = try src_field.map(dst_field.type);
                    if (idx >= self.fields.len) break;
                }
                break :D st;
            },
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Struct: {any}", .{self.fields});
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();
        for (self.fields, 0..) |field, idx| {
            var buf: [8]u8 = undefined;
            const len = std.fmt.formatIntBuf(&buf, idx, 10, .lower, .{});
            try jws.objectField(buf[0..len]);
            try jws.write(field);
        }
        try jws.endObject();
    }
};

pub const Object = union(spa.id.Object) {
    pub const AnyProperty = struct {
        key: u32,
        flags: u32,
        pod: Pod,

        pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
            var val: @This() = undefined;
            if (try reader.readAll(std.mem.asBytes(&val.key)) != 4) return error.InvalidProperty;
            if (try reader.readAll(std.mem.asBytes(&val.flags)) != 4) return error.InvalidProperty;
            val.pod = try .read(arena, @intCast(size - 8), reader);
            return val;
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("Property: {}, {}: {}", .{ self.key, self.flags, self.pod });
        }
    };

    fn Property(T: anytype) type {
        return struct {
            id: Id,
            props: []const T,

            pub fn read(arena: std.mem.Allocator, id: Id, size: u32, reader: anytype) !@This() {
                var counter = std.io.countingReader(reader);
                var props: std.ArrayListUnmanaged(T) = .empty;
                errdefer props.deinit(arena);
                while (counter.bytes_read < size) {
                    var any: AnyProperty = try .read(arena, size, counter.reader());
                    inline for (std.meta.fields(std.meta.Tag(T))) |field| {
                        if (field.value == any.key) {
                            try props.append(arena, @unionInit(T, field.name, try any.pod.map(@FieldType(T, field.name))));
                        }
                    }
                }
                return .{ .id = id, .props = try props.toOwnedSlice(arena) };
            }

            pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
                try writer.print("{}: {any}", .{ self.id, self.props });
            }

            pub fn jsonStringify(self: @This(), jws: anytype) !void {
                try jws.beginObject();
                try jws.objectField("~id");
                try jws.write(self.id);
                for (self.props) |prop| switch (prop) {
                    inline else => |payload, tag| {
                        try jws.objectField(@tagName(tag));
                        if (@TypeOf(payload) == void) {
                            try jws.write(null);
                        } else {
                            try jws.write(payload);
                        }
                    },
                };
                try jws.endObject();
            }
        };
    }

    prop_info: Property(spa.param.PropInfo),
    props: Property(spa.param.Prop),
    media_format: Property(spa.param.Format),
    param_buffers: Property(spa.param.Buffers),
    param_meta: Property(spa.param.Meta),
    param_io: Property(spa.param.Io),
    param_profile: Property(spa.param.Profile),
    param_port_config: Property(spa.param.PortConfig),
    param_route: Property(spa.param.Route),
    profiler: Property(spa.param.Profile),
    param_latency: Property(spa.param.Latency),
    param_process_latency: Property(spa.param.ProcessLatency),
    param_tag: Property(spa.param.Tag),

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var id: Id = undefined;
        var raw_type: u32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&raw_type)) != 4) return error.InvalidObject;
        if (try reader.readAll(std.mem.asBytes(&id)) != 4) return error.InvalidObject;
        const obj_type = std.meta.intToEnum(spa.id.Object, raw_type) catch return error.InvalidObject;
        const props_size = size - 8;
        var buf = try arena.alloc(u8, props_size);
        errdefer arena.free(buf);
        if (try reader.readAll(buf[0..]) != props_size) return error.InvalidObject;
        var child_reader = std.io.fixedBufferStream(buf[0..props_size]);
        switch (obj_type) {
            inline else => |tag| {
                return @unionInit(@This(), @tagName(tag), try .read(arena, id, props_size, child_reader.reader()));
            },
        }
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        @panic("fixme");
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |payload, tag| {
                try writer.print("{s}!{}", .{ @tagName(tag), payload });
            },
        }
    }
};

pub const Sequence = struct {
    pub const Control = struct {
        offset: u32,
        type: u32,
        pod: Pod,

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("Control: {}, {}: {}", .{ self.offset, self.type, self.pod });
        }
    };

    unit: u32,
    pad: u32,
    controls: []const Control,

    pub fn read(_: std.mem.Allocator, _: u32, _: anytype) !@This() {
        @panic("fixme");
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        @panic("fixme");
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Sequence: {}, {}: {any}", .{ self.unit, self.pad, self.controls });
    }
};

pub const Pointer = enum(usize) {
    _,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidPointer;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidPointer;
        return val;
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"enum" => std.meta.intToEnum(T, @intFromEnum(self)) catch error.IncompatibleDestinationType,
            .int => std.math.cast(T, @intFromEnum(self)) orelse error.IncompatibleDestinationType,
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const val: usize = @intFromEnum(self);
        try writer.print("Pointer:{x}", .{val});
    }
};

pub const Fd = enum(u64) {
    _,

    pub fn read(_: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        if (size != 8) return error.InvalidFd;
        var val: @This() = undefined;
        if (try reader.readAll(std.mem.asBytes(&val)) != 8) return error.InvalidFd;
        return val;
    }

    pub fn write(val: anytype, writer: anytype) !void {
        const header: Header = .{ .type = .fd, .size = 8 };
        try writer.writeAll(std.mem.asBytes(&header));
        const fdint: u64 = @intFromEnum(val);
        try writer.writeAll(std.mem.asBytes(&fdint));
    }

    pub fn writeSelf(self: @This(), writer: anytype) !void {
        return write(self, writer);
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return switch (@typeInfo(T)) {
            .@"enum" => std.meta.intToEnum(T, @intFromEnum(self)) catch error.IncompatibleDestinationType,
            .int => std.math.cast(T, @intFromEnum(self)) orelse error.IncompatibleDestinationType,
            .optional => |ti| self.map(ti.child) catch null,
            else => error.IncompatibleDestinationType,
        };
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const val: u64 = @intFromEnum(self);
        try writer.print("Fd:{}", .{val});
    }
};

pub const Choice = struct {
    pub const Kind = enum {
        none,
        range,
        step,
        @"enum",
        flags,
    };

    kind: Kind,
    flags: u32,
    choices: []const Pod,

    pub fn read(arena: std.mem.Allocator, size: u32, reader: anytype) !@This() {
        var val: @This() = undefined;
        var raw_kind: u32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&raw_kind)) != 4) return error.InvalidChoice;
        if (try reader.readAll(std.mem.asBytes(&val.flags)) != 4) return error.InvalidChoice;
        val.kind = std.meta.intToEnum(Kind, raw_kind) catch return error.InvalidChoice;
        if (val.flags != 0) return error.InvalidChoice;

        var child_size: u32 = undefined;
        var child_raw_type: u32 = undefined;
        if (try reader.readAll(std.mem.asBytes(&child_size)) != 4) return error.InvalidChoice;
        if (try reader.readAll(std.mem.asBytes(&child_raw_type)) != 4) return error.InvalidChoice;

        const child_type = std.meta.intToEnum(Pod.Type, child_raw_type) catch return error.InvalidChoice;
        const array_size = size - 16;
        const n_items = array_size / child_size;

        switch (val.kind) {
            .none => if (n_items == 0) return error.InvalidChoice,
            .range => if (n_items != 3) return error.InvalidChoice,
            .step => if (n_items != 4) return error.InvalidChoice,
            .@"enum" => if (n_items == 0) return error.InvalidChoice,
            .flags => if (n_items == 0) return error.InvalidChoice,
        }

        const items = try arena.alloc(Pod, n_items);
        errdefer arena.free(items);
        for (items) |*item| item.* = try .readType(arena, child_type, child_size, .dont_align, reader);
        val.choices = items;
        return val;
    }

    pub fn write(_: anytype, _: anytype) !void {
        @panic("fixme");
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        @panic("fixme");
    }

    pub fn map(self: @This(), T: type) !T {
        if (T == @This()) return self;
        return self.choices[0].map(T);
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try switch (self.kind) {
            .none => writer.print("none: {}", .{self.choices[0]}),
            .range => writer.print("range: {} ({}..{})", .{ self.choices[0], self.choices[1], self.choices[2] }),
            .step => writer.print("step: {} ({}..{} + {})", .{ self.choices[0], self.choices[1], self.choices[2], self.choices[3] }),
            .@"enum" => writer.print("enum: {} ({any})", .{ self.choices[0], self.choices[1..] }),
            .flags => writer.print("flags: {} ({any})", .{ self.choices[0], self.choices[1..] }),
        };
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        switch (self.kind) {
            .none => try jws.write(self.choices[0]),
            .range => {
                try jws.beginObject();
                try jws.objectField("default");
                try jws.write(self.choices[0]);
                try jws.objectField("min");
                try jws.write(self.choices[1]);
                try jws.objectField("max");
                try jws.write(self.choices[2]);
                try jws.endObject();
            },
            .step => {
                try jws.beginObject();
                try jws.objectField("default");
                try jws.write(self.choices[0]);
                try jws.objectField("min");
                try jws.write(self.choices[1]);
                try jws.objectField("max");
                try jws.write(self.choices[2]);
                try jws.objectField("step");
                try jws.write(self.choices[3]);
                try jws.endObject();
            },
            .@"enum", .flags => try jws.write(self.choices),
        }
    }
};

pub const Self = struct {
    pub fn read(_: std.mem.Allocator, _: u32, _: anytype) !@This() {
        unreachable;
    }

    pub fn write(_: void, _: anytype) !void {
        unreachable;
    }

    pub fn writeSelf(_: @This(), _: anytype) !void {
        unreachable;
    }

    pub fn map(_: @This(), T: type) !T {
        unreachable;
    }

    pub fn format(_: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("Self");
    }
};

pub fn PodMap(comptime Key: Pod.Type, comptime Value: Pod.Type, comptime Tag: ?type, KV: type) type {
    return struct {
        fields: []const Pod,

        pub fn init(pod: Pod) !@This() {
            if (pod != .@"struct") return error.InvalidMap;
            const st = pod.@"struct";
            if (st.fields.len <= 0) return error.InvalidMap;
            if (st.fields[0] != .int) return error.InvalidMap;
            const n_fields: usize = @intCast(@intFromEnum(st.fields[0].int));
            if (n_fields * 2 > st.fields.len - 1) return error.InvalidMap;
            var idx: usize = 0;
            while (idx < n_fields) : (idx += 2) {
                if (st.fields[1..][idx + 0] != Key) return error.InvalidMap;
                if (st.fields[1..][idx + 1] != Value) return error.InvalidMap;
                const key = st.fields[1..][idx];
                if (Tag) |TagType| {
                    _ = switch (Key) {
                        .string => std.meta.stringToEnum(TagType, key.string.slice) catch return error.InvalidMap,
                        inline .int, .long, .id => switch (key) {
                            inline .int, .long, .id => |v| std.meta.intToEnum(TagType, @intFromEnum(v)) catch return error.InvalidMap,
                            else => unreachable,
                        },
                        else => @compileError("unsupported key"),
                    };
                }
            }
            return .{ .fields = st.fields[1..][0 .. n_fields * 2] };
        }

        fn keyName(self: @This(), idx: usize) []const u8 {
            const key = self.fields[idx];
            if (Tag) |TagType| {
                return switch (Key) {
                    .string => std.meta.stringToEnum(TagType, key.string.slice) catch return error.Corrupted,
                    inline .int, .long, .id => switch (key) {
                        inline .int, .long, .id => |v| @tagName(@as(TagType, @enumFromInt(@intFromEnum(v)))),
                        else => unreachable,
                    },
                    else => @compileError("unsupported key"),
                };
            } else {
                return switch (Key) {
                    .string => key.string.slice,
                    else => @compileError("tag required for non string key"),
                };
            }
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            var iter = self.iterator();
            while (iter.next()) |kv| try writer.print("{}", .{kv});
        }

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginObject();
            var iter = self.iterator();
            while (iter.next()) |kv| try kv.jsonStringifyRaw(jws);
            try jws.endObject();
        }

        const Container = @This();

        pub const Iterator = struct {
            container: *const Container,
            cursor: usize = 0,

            pub fn next(self: *@This()) ?KV {
                if (self.cursor >= self.container.fields.len) return null;
                defer self.cursor += 2;
                var kv: KV = undefined;
                inline for (std.meta.fields(KV), 0..) |field, idx| {
                    const pod = self.container.fields[self.cursor + idx];
                    @field(kv, field.name) = pod.map(field.type) catch unreachable;
                    if (idx > 1) @compileError("KV should only contain 2 fields");
                }
                return kv;
            }
        };

        pub fn iterator(self: *const @This()) Iterator {
            return .{ .container = self };
        }

        pub fn map(self: @This(), T: type) !T {
            const ti = @typeInfo(T);
            if (ti != .@"struct") @compileError("T must be a struct");
            var st: T = undefined;
            inline for (ti.@"struct".fields) |dst_field| {
                comptime var error_if_not_found = true;
                if (dst_field.defaultValue()) |def| {
                    @field(st, dst_field.name) = def;
                    error_if_not_found = false;
                } else if (@typeInfo(dst_field.type) == .optional) {
                    @field(st, dst_field.name) = null;
                    error_if_not_found = false;
                }
                var found: bool = false;
                var idx: usize = 0;
                while (idx < self.fields.len) : (idx += 2) {
                    if (std.mem.eql(u8, self.keyName(idx), dst_field.name)) {
                        const value = self.fields[idx + 1];
                        if (@typeInfo(dst_field.type) == .optional) {
                            @field(st, dst_field.name) = try value.map(std.meta.Child(dst_field.type));
                        } else {
                            @field(st, dst_field.name) = try value.map(dst_field.type);
                        }
                        found = true;
                        break;
                    }
                }
                if (error_if_not_found and !found) {
                    std.log.debug("missing: {s}", .{dst_field.name});
                    return error.Corrupted;
                }
            }
            return st;
        }
    };
}

pub fn PodList(comptime Key: Pod.Type, comptime Value: Pod.Type, KV: type) type {
    return struct {
        fields: []const Pod,

        pub fn init(pod: Pod) !@This() {
            if (pod != .@"struct") return error.InvalidList;
            const st = pod.@"struct";
            if (st.fields.len <= 0) return error.InvalidList;
            if (st.fields[0] != .int) return error.InvalidList;
            const n_fields: usize = @intCast(@intFromEnum(st.fields[0].int));
            if (n_fields * 2 > st.fields.len - 1) return error.InvalidList;
            var idx: usize = 0;
            while (idx < n_fields) : (idx += 2) {
                if (st.fields[1..][idx + 0] != Key) return error.InvalidList;
                if (st.fields[1..][idx + 1] != Value) return error.InvalidList;
            }
            return .{ .fields = st.fields[1..][0 .. n_fields * 2] };
        }

        pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            var iter = self.iterator();
            while (iter.next()) |kv| try writer.print("{}", .{kv});
        }

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginArray();
            var iter = self.iterator();
            while (iter.next()) |kv| try jws.write(kv);
            try jws.endArray();
        }

        const Container = @This();

        pub const Iterator = struct {
            container: *const Container,
            cursor: usize = 0,

            pub fn next(self: *@This()) ?KV {
                if (self.cursor >= self.container.fields.len) return null;
                defer self.cursor += 2;
                var kv: KV = undefined;
                inline for (std.meta.fields(KV), 0..) |field, idx| {
                    const pod = self.container.fields[self.cursor + idx];
                    @field(kv, field.name) = pod.map(field.type) catch unreachable;
                    if (idx > 1) @compileError("KV should only contain 2 fields");
                }
                return kv;
            }
        };

        pub fn iterator(self: *const @This()) Iterator {
            return .{ .container = self };
        }
    };
}

pub const Prop = struct {
    pub const Map = PodMap(.string, .string, null, @This());

    key: [:0]const u8,
    value: [:0]const u8,

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{} = {}", .{ self.key, self.value });
    }

    fn jsonStringifyRaw(self: @This(), jws: anytype) !void {
        try jws.objectField(self.key);
        try jws.write(self.value);
    }
};

pub const ParamInfo = struct {
    pub const Map = PodMap(.id, .int, spa.wire.ParamType, @This());

    id: spa.wire.ParamType,
    flags: spa.flags.Param,

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{} = {}", .{ self.id, self.flags });
    }

    fn jsonStringifyRaw(self: @This(), jws: anytype) !void {
        try jws.objectField(@tagName(self.id));
        try jws.write(self.flags);
    }
};

pub const IdPermission = struct {
    pub const List = PodList(.id, .int, @This());

    id: Id,
    permission: spa.flags.Permission,

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{} = {}", .{ self.id, self.permission });
    }
};
