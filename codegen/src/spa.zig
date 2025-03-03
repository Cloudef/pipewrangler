const std = @import("std");
const codegen = @import("codegen.zig");

pub const TAG = .@"codegen::spa";
pub const log = std.log.scoped(TAG);

pub fn main() !void {
    var ctx = try codegen.setup(std.heap.page_allocator, TAG);
    defer ctx.deinit();
    const allocator = ctx.arena.allocator();

    var dir = try ctx.src.openDir("spa/include", .{});
    defer dir.close();
    const ast: codegen.Ast = try .parse(allocator, .{
        .node = ctx.node,
        .zig = ctx.zig,
        .cwd = dir,
        .transform = .{
            .remove_prefixes = &.{ "spa_", "_spa_" },
            .renamed_anonymous = &.{
                "TypeId", // spa/utils/type.h
            },
            .renamed_identifiers = &.{
                .{ "SPA_DIRECTION_INPUT", "SPA_DIRECTION_IN" },
                .{ "SPA_DIRECTION_OUTPUT", "SPA_DIRECTION_OUT" },
                .{ "SPA_TYPE_OBJECT_Format", "SPA_TYPE_OBJECT_MediaFormat" },
                .{ "SPA_PARAM_EnumFormat", "SPA_PARAM_EnumMediaFormat" },
                .{ "SPA_PARAM_Format", "SPA_PARAM_MediaFormat" },
                .{ "spa_meta_videotransform_value", "spa_meta_video_transform_value" },
                .{ "SPA_META_TRANSFORMATION_90", "SPA_META_TRANSFORMATION_CCW_90" },
                .{ "SPA_META_TRANSFORMATION_180", "SPA_META_TRANSFORMATION_CCW_180" },
                .{ "SPA_META_TRANSFORMATION_270", "SPA_META_TRANSFORMATION_CCW_270" },
                .{ "SPA_META_TRANSFORMATION_Flipped90", "SPA_META_TRANSFORMATION_FLIPPED_CCW_90" },
                .{ "SPA_META_TRANSFORMATION_Flipped180", "SPA_META_TRANSFORMATION_FLIPPED_CCW_180" },
                .{ "SPA_META_TRANSFORMATION_Flipped270", "SPA_META_TRANSFORMATION_FLIPPED_CCW_270" },
                .{ "SPA_VIDEO_COLOR_RANGE_0_255", "SPA_VIDEO_COLOR_RANGE_U8_0_255" },
                .{ "SPA_VIDEO_COLOR_RANGE_16_235", "SPA_VIDEO_COLOR_RANGE_U8_16_235" },
            },
            .excluded_identifiers = &.{"\\ {"},
            .force_as_decl = &.{
                "SPA_TYPE_START",
                "_SPA_TYPE_LAST",
                "SPA_TYPE_POINTER_START",
                "_SPA_TYPE_POINTER_LAST",
                "SPA_TYPE_EVENT_START",
                "_SPA_TYPE_EVENT_LAST",
                "SPA_TYPE_COMMAND_START",
                "_SPA_TYPE_COMMAND_LAST",
                "SPA_TYPE_OBJECT_START",
                "_SPA_TYPE_OBJECT_LAST",
                "_SPA_META_LAST",
                "_SPA_CONTROL_LAST",
                "_SPA_DATA_LAST",
                "SPA_TYPE_VENDOR_PipeWire",
                "SPA_TYPE_VENDOR_Other",
                "SPA_PROP_INFO_START",
                "SPA_PROP_START",
                "SPA_PROP_START_Device",
                "SPA_PROP_START_Audio",
                "SPA_PROP_START_Video",
                "SPA_PROP_START_Other",
                "SPA_PROP_START_CUSTOM",
                "SPA_FORMAT_START",
                "SPA_FORMAT_START_Audio",
                "SPA_FORMAT_START_Video",
                "SPA_FORMAT_START_Image",
                "SPA_FORMAT_START_Binary",
                "SPA_FORMAT_START_Stream",
                "SPA_FORMAT_START_Application",
                "SPA_MEDIA_SUBTYPE_START_Audio",
                "SPA_MEDIA_SUBTYPE_START_Video",
                "SPA_MEDIA_SUBTYPE_START_Image",
                "SPA_MEDIA_SUBTYPE_START_Binary",
                "SPA_MEDIA_SUBTYPE_START_Stream",
                "SPA_MEDIA_SUBTYPE_START_Application",
                "SPA_AUDIO_FORMAT_START_Interleaved",
                "SPA_AUDIO_FORMAT_START_Planar",
                "SPA_AUDIO_FORMAT_START_Other",
                "SPA_AUDIO_CHANNEL_START_Aux",
                "SPA_AUDIO_CHANNEL_LAST_Aux",
                "SPA_AUDIO_CHANNEL_START_Custom",
                "SPA_PARAM_BUFFERS_START",
                "SPA_PARAM_META_START",
                "SPA_PARAM_IO_START",
                "SPA_PARAM_PROFILE_START",
                "SPA_PARAM_PORT_CONFIG_START",
                "SPA_PARAM_ROUTE_START",
                "SPA_PARAM_LATENCY_START",
                "SPA_PARAM_PROCESS_LATENCY_START",
                "SPA_PARAM_TAG_START",
                "SPA_PROFILER_START",
                "SPA_PROFILER_START_Driver",
                "SPA_PROFILER_START_Follower",
                "SPA_PROFILER_START_CUSTOM",
                "SPA_BLUETOOTH_AUDIO_CODEC_START",
                "SPA_EVENT_NODE_START",
                "SPA_EVENT_DEVICE_START",
            },
        },
    }, &.{
        "spa/pod/pod.h",
        "spa/utils/type.h",
        "spa/utils/keys.h",
        "spa/utils/names.h",
        "spa/support/cpu.h",
        "spa/support/dbus.h",
        "spa/support/log.h",
        "spa/support/thread.h",
        "spa/param/buffers.h",
        "spa/param/format.h",
        "spa/param/latency.h",
        "spa/param/param.h",
        "spa/param/port-config.h",
        "spa/param/profile.h",
        "spa/param/profiler.h",
        "spa/param/props.h",
        "spa/param/route.h",
        "spa/param/tag.h",
        "spa/param/video/chroma.h",
        "spa/param/video/color.h",
        "spa/param/video/format.h",
        "spa/param/video/h264.h",
        "spa/param/video/multiview.h",
        "spa/param/bluetooth/audio.h",
        "spa/param/audio/format.h",
        "spa/buffer/alloc.h",
        "spa/buffer/buffer.h",
        "spa/buffer/meta.h",
        "spa/control/control.h",
        "spa/node/command.h",
        "spa/node/event.h",
        "spa/node/io.h",
        "spa/node/keys.h",
        "spa/node/node.h",
        "spa/monitor/device.h",
        "spa/monitor/event.h",
    });

    {
        var file = try ctx.out.createFile("spa.zig", .{});
        defer file.close();

        const writer = file.writer();
        for (ast.enums.items, 0..) |enm, idx| {
            if (idx > 0) try writer.writeAll("\n");
            try writer.print("pub const {s} = enum (u32) {{\n", .{enm.name});
            var last_value: u64 = D: {
                for (enm.fields) |field| if (!field.decl) break :D try field.value.intValue(u64);
                break :D 0;
            };
            for (enm.fields) |field| {
                if (field.decl) continue;
                if (field.comment) |comment| try writer.print("/// {s}\n", .{comment});
                if (field.value == .int and try field.value.intValue(u64) == last_value + 1) {
                    try writer.print("{s},\n", .{field.name});
                } else {
                    if (field.value == .int) {
                        try writer.print("{s} = 0x{x},\n", .{ field.name, try field.value.intValue(u64) });
                    } else {
                        try writer.print("{s} = ", .{field.name});
                        try field.value.render(writer);
                        try writer.writeAll(",\n");
                    }
                }
                last_value = try field.value.intValue(u64);
            }
            for (enm.fields) |field| {
                if (!field.decl) continue;
                if (field.comment) |comment| try writer.print("/// {s}\n", .{comment});
                if (field.value == .int) {
                    try writer.print("pub const {s} = 0x{x};\n", .{ field.name, try field.value.intValue(u64) });
                } else {
                    try writer.print("pub const {s} = ", .{field.name});
                    try field.value.render(writer);
                    try writer.writeAll(";\n");
                }
            }
            try writer.writeAll("};\n");
        }
    }
}
