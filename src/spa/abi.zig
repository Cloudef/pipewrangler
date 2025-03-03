const std = @import("std");

pub fn assertEnum(Schema: type, Impl: type, start_field: @TypeOf(.enum_literal), last_field: @TypeOf(.enum_literal)) void {
    if (!@inComptime()) @compileError("function must be used in comptime context");
    const impl = std.meta.fields(Impl);
    const start_off = @field(Schema, @tagName(start_field)) + 1;
    const len = @field(Schema, @tagName(last_field)) - start_off;
    const start: usize = D: {
        for (std.meta.fields(Schema), 0..) |field, idx| if (field.value == start_off) break :D idx;
        @compileError("could not find the starting enum field from the schema");
    };
    const schema = std.meta.fields(Schema)[start .. start + len];
    for (impl[0..], schema[0..]) |a, b| {
        std.debug.assert(a.value == b.value);
        std.debug.assert(std.mem.endsWith(u8, b.name, a.name));
    }
}
