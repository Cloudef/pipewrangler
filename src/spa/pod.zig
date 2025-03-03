//! Pipewire POD type
//! <https://docs.pipetypes.org/page_spa_pod.html>

const std = @import("std");
const spa = @import("spa.zig");
pub const types = @import("pod_types.zig");

pub const MapError = error{
    InvalidMap,
    InvalidList,
    IncompatibleDestinationType,
};

pub const ReadError = error{
    InvalidPod,
    InvalidPodHeader,
    InvalidNone,
    InvalidBool,
    InvalidId,
    InvalidInt,
    InvalidLong,
    InvalidFloat,
    InvalidDouble,
    InvalidString,
    InvalidBytes,
    InvalidRectangle,
    InvalidFraction,
    InvalidBitmap,
    InvalidArray,
    InvalidStruct,
    InvalidObject,
    InvalidProperty,
    InvalidPointer,
    InvalidFd,
    InvalidChoice,
    EndOfStream,
    OutOfMemory,
} || MapError || std.net.Stream.ReadError;

pub const WriteError = std.net.Stream.WriteError;

pub const Pod = union(spa.id.Pod) {
    pub const Type = spa.id.Pod;
    none: types.None,
    bool: types.Bool,
    id: types.Id,
    int: types.Int,
    long: types.Long,
    float: types.Float,
    double: types.Double,
    string: types.String,
    bytes: types.Bytes,
    rectangle: types.Rectangle,
    fraction: types.Fraction,
    bitmap: types.Bitmap,
    array: types.Array,
    @"struct": types.Struct,
    object: types.Object,
    sequence: types.Sequence,
    pointer: types.Pointer,
    fd: types.Fd,
    choice: types.Choice,
    pod: types.Self,

    pub fn readType(arena: std.mem.Allocator, kind: Type, size: u32, aligned: enum { align_after, dont_align }, reader: anytype) ReadError!@This() {
        switch (kind) {
            inline else => |tag| {
                const WireType = @FieldType(@This(), @tagName(tag));
                const payload = try WireType.read(arena, size, reader);
                const pod = @unionInit(@This(), @tagName(tag), payload);
                if (aligned == .align_after) {
                    try reader.skipBytes(std.mem.alignForward(usize, size, 8) - size, .{});
                }
                return pod;
            },
        }
    }

    pub fn read(arena: std.mem.Allocator, size: u24, reader: anytype) ReadError!@This() {
        if (size < @sizeOf(types.Header)) return error.InvalidPod;
        const header = try types.Header.read(reader);
        return readType(arena, header.type, header.size, .align_after, reader);
    }

    pub fn map(self: @This(), T: type) MapError!T {
        return switch (T) {
            Pod => self,
            types.Prop.Map,
            types.ParamInfo.Map,
            types.IdPermission.List,
            => .init(self),
            else => switch (self) {
                inline else => |pod| pod.map(T),
            },
        };
    }

    pub fn writeSelf(self: @This(), writer: anytype) WriteError!void {
        switch (self) {
            inline else => |v| try v.writeSelf(writer),
        }
    }

    pub fn write(val: anytype, writer: anytype) WriteError!void {
        switch (@TypeOf(val)) {
            Pod => try val.writeSelf(writer),
            types.Id,
            spa.id.Pod,
            spa.id.Object,
            spa.wire.ParamType,
            => try types.Id.write(val, writer),
            types.Fd => try types.Fd.write(val, writer),
            []const types.Prop => {
                var counter = std.io.countingWriter(std.io.null_writer);
                const len: u32 = @intCast(val.len);
                try write(len, counter.writer());
                for (val) |kv| {
                    try write(kv.key, counter.writer());
                    try write(kv.value, counter.writer());
                }
                const header: types.Header = .{
                    .type = .@"struct",
                    .size = @intCast(counter.bytes_written),
                };
                try writer.writeAll(std.mem.asBytes(&header));
                try write(len, writer);
                for (val) |kv| {
                    try write(kv.key, writer);
                    try write(kv.value, writer);
                }
            },
            []const types.IdPermission => {
                var counter = std.io.countingWriter(std.io.null_writer);
                const len: u32 = @intCast(val.len);
                try write(len, counter.writer());
                for (val) |kv| {
                    try write(kv.id, counter.writer());
                    try write(kv.permission, counter.writer());
                }
                const header: types.Header = .{
                    .type = .@"struct",
                    .size = @intCast(counter.bytes_written),
                };
                try writer.writeAll(std.mem.asBytes(&header));
                try write(len, writer);
                for (val) |kv| {
                    try write(kv.id, writer);
                    try write(kv.permission, writer);
                }
            },
            else => |T| switch (@typeInfo(T)) {
                .void => try types.None.write(val, writer),
                .bool => try types.Bool.write(val, writer),
                .int => |ti| {
                    if (ti.bits <= 32) {
                        try types.Int.write(@intCast(val), writer);
                    } else if (ti.bits <= 64) {
                        try types.Long.write(@intCast(val), writer);
                    } else {
                        @compileError("integers larger than 64 bits cannot be written");
                    }
                },
                .@"enum" => |ti| {
                    const tag: ti.tag_type = @intFromEnum(val);
                    try write(tag, writer);
                },
                .float => |ti| {
                    if (ti.bits <= 32) {
                        try types.Float.write(@floatCast(val), writer);
                    } else if (ti.bits <= 64) {
                        try types.Double.write(@floatCast(val), writer);
                    } else {
                        @compileError("floats larger than 64 bits cannot be written");
                    }
                },
                .pointer => |ti| switch (ti.size) {
                    .slice => switch (ti.child) {
                        u8 => {
                            if (ti.sentinel() == 0) {
                                try types.String.write(val, writer);
                            } else {
                                try types.Bytes.write(val, writer);
                            }
                        },
                        else => try types.Array.write(val, writer),
                    },
                    else => try types.Pointer.write(val, writer),
                },
                .array => |ti| switch (ti.child) {
                    u8 => {
                        if (ti.sentinel() == 0) {
                            try types.String.write(val[0.. :0], writer);
                        } else {
                            try types.Bytes.write(val[0..], writer);
                        }
                    },
                    else => try types.Array.write(val[0..], writer),
                },
                .@"struct" => |ti| switch (ti.layout) {
                    .@"packed" => {
                        const int: ti.backing_integer.? = @bitCast(val);
                        try write(int, writer);
                    },
                    else => try types.Struct.write(val, writer),
                },
                .optional => switch (val) {
                    null => try write({}, writer),
                    else => |child| write(child, writer),
                },
                else => @compileError(std.fmt.comptimePrint("type `{}` is not supported", .{@TypeOf(val)})),
            },
        }
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        return switch (self) {
            inline else => |tag| writer.print("{any}", .{tag}),
        };
    }

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        return switch (self) {
            inline else => |tag| jws.write(tag),
        };
    }
};
