const wire = @import("generated/spa.zig");
const abi = @import("abi.zig");

pub const Pod = enum(u32) {
    none = @intFromEnum(wire.TypeId.none),
    bool,
    id,
    int,
    long,
    float,
    double,
    string,
    bytes,
    rectangle,
    fraction,
    bitmap,
    array,
    @"struct",
    object,
    sequence,
    pointer,
    fd,
    choice,
    pod,
};

comptime {
    abi.assertEnum(wire.TypeId, Pod, .start, .last);
}

pub const Object = enum(u32) {
    prop_info = @intFromEnum(wire.TypeId.object_prop_info),
    props,
    media_format,
    param_buffers,
    param_meta,
    param_io,
    param_profile,
    param_port_config,
    param_route,
    profiler,
    param_latency,
    param_process_latency,
    param_tag,
};

comptime {
    abi.assertEnum(wire.TypeId, Object, .object_start, .object_last);
}
