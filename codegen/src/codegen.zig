const std = @import("std");
const root = @import("root");

pub const CodegenContext = struct {
    arena: std.heap.ArenaAllocator,
    zig: []const u8,
    src: std.fs.Dir,
    out: std.fs.Dir,
    node: std.Progress.Node,

    fn fmt(self: *@This()) !void {
        const res = try std.process.Child.run(.{
            .allocator = self.arena.allocator(),
            .argv = &.{ self.zig, "fmt", "." },
            .cwd_dir = self.out,
            .progress_node = self.node,
        });
        defer self.arena.allocator().free(res.stderr);
        defer self.arena.allocator().free(res.stdout);
        if (res.term.Exited != 0) {
            root.log.err("{s}", .{res.stderr});
            return error.ZigFmtFailed;
        }
    }

    pub fn deinit(self: *@This()) void {
        self.fmt() catch unreachable;
        self.node.end();
        self.arena.deinit();
        self.src.close();
        self.out.close();
        self.* = undefined;
    }
};

pub fn setup(allocator: std.mem.Allocator, tag: @TypeOf(.enum_literal)) !CodegenContext {
    var arena: std.heap.ArenaAllocator = .init(allocator);
    errdefer arena.deinit();
    var args = try std.process.argsWithAllocator(arena.allocator());
    _ = args.skip();
    const zig = args.next() orelse return error.NoZigProvided;
    const src = args.next() orelse return error.NoSrcDirProvided;
    const out = args.next() orelse return error.NoOutDirProvided;
    const stdout = std.io.getStdOut().writer();
    stdout.print("zig: {s}\n", .{zig}) catch {};
    stdout.print("src: {s}\n", .{src}) catch {};
    stdout.print("out: {s}\n", .{out}) catch {};
    return .{
        .arena = arena,
        .zig = zig,
        .src = try std.fs.cwd().openDir(src, .{}),
        .out = try std.fs.cwd().openDir(out, .{}),
        .node = std.Progress.start(.{ .root_name = @tagName(tag) }),
    };
}

pub const KeyValue = struct { []const u8, []const u8 };

pub const Transform = struct {
    /// Remove these prefixes from identifiers
    remove_prefixes: []const []const u8 = &.{},

    /// Renames anonymous identifiers in this order
    renamed_anonymous: []const []const u8 = &.{},

    /// Rename identifiers matching the key to a value
    /// This is before any other transformations
    renamed_identifiers: []const KeyValue = &.{},

    /// Exclude these identifiers from generation
    /// This is before any other transformations
    excluded_identifiers: []const []const u8 = &.{},

    /// If the identifier is a field, convert it to decl instead
    /// Useful if C enums contain fields that are not part of the ABI itself
    force_as_decl: []const []const u8 = &.{},

    // internal tracking
    num_anon: u32 = 0,

    fn name(self: *@This()) ?[]const u8 {
        if (self.num_anon >= self.renamed_anonymous.len) return null;
        defer self.num_anon += 1;
        return self.renamed_anonymous[self.num_anon];
    }

    fn renamed(self: @This(), identifier: []const u8) []const u8 {
        for (self.renamed_identifiers) |kv| {
            if (std.mem.eql(u8, kv[0], identifier)) return kv[1];
        }
        return identifier;
    }

    fn isExcluded(self: @This(), identifier: []const u8) bool {
        for (self.excluded_identifiers) |exclusion| {
            if (std.mem.eql(u8, exclusion, identifier)) return true;
        }
        return false;
    }

    fn isForcedDecl(self: @This(), identifier: []const u8) bool {
        for (self.force_as_decl) |decl| {
            if (std.mem.eql(u8, decl, identifier)) return true;
        }
        return false;
    }

    pub const Context = struct {
        kind: enum {
            type_name,
            field_name,
        },
    };

    fn process(self: @This(), allocator: std.mem.Allocator, identifier: []const u8, ctx: Context) ![]const u8 {
        var cpy = try allocator.dupe(u8, self.renamed(identifier));
        for (self.remove_prefixes) |prefix| cpy = removePrefix(cpy, prefix);
        switch (ctx.kind) {
            .type_name => cpy = try toPascalCase(allocator, cpy),
            .field_name => cpy = try toSnakeCase(allocator, cpy),
        }
        return renameReserved(cpy);
    }

    fn removePrefix(identifier: anytype, prefix: []const u8) @TypeOf(identifier) {
        if (prefix.len >= identifier.len) return identifier;
        for (identifier[0..prefix.len], prefix[0..]) |a, b| {
            if (std.ascii.toLower(a) != std.ascii.toLower(b)) return identifier;
        }
        const stripped = identifier[prefix.len..];
        if (std.ascii.isDigit(stripped[0])) return identifier;
        return stripped;
    }

    fn toPascalCase(allocator: std.mem.Allocator, identifier: []u8) ![]u8 {
        var result: std.ArrayListUnmanaged(u8) = try .initCapacity(allocator, identifier.len);
        defer result.deinit(allocator);
        var it = std.mem.tokenizeAny(u8, identifier, "_");
        while (it.next()) |word| {
            if (word.len == 0) continue;
            var first = word[0];
            if (std.ascii.isLower(first)) first = std.ascii.toUpper(first);
            try result.append(allocator, first);
            if (word.len > 1) try result.appendSlice(allocator, word[1..]);
        }
        @memcpy(identifier[0..result.items.len], result.items[0..]);
        return identifier[0..result.items.len];
    }

    fn toSnakeCase(allocator: std.mem.Allocator, identifier: []u8) ![]u8 {
        var result: std.ArrayListUnmanaged(u8) = try .initCapacity(allocator, identifier.len);
        errdefer result.deinit(allocator);

        for (identifier, 0..) |chr, idx| {
            const last = if (idx > 0) identifier[idx - 1] else chr;
            if (chr != '_' and last != '_' and std.ascii.isUpper(chr)) {
                if (std.ascii.isLower(last) or !std.ascii.isAlphabetic(last)) {
                    try result.append(allocator, '_');
                }
            }
            try result.append(allocator, std.ascii.toLower(chr));
        }

        const cpy = try result.toOwnedSlice(allocator);
        allocator.free(identifier);
        return cpy;
    }

    fn renameReserved(identifier: []const u8) []const u8 {
        const Reserved = enum {
            @"addrspace",
            @"align",
            @"allowzero",
            @"and",
            @"anyframe",
            @"anytype",
            @"asm",
            @"async",
            @"await",
            @"break",
            @"callconv",
            @"catch",
            @"comptime",
            @"const",
            @"continue",
            @"defer",
            @"else",
            @"enum",
            @"errdefer",
            @"error",
            @"export",
            @"extern",
            @"fn",
            @"for",
            @"if",
            @"inline",
            @"noalias",
            @"noinline",
            @"nosuspend",
            @"opaque",
            @"or",
            @"orelse",
            @"packed",
            @"pub",
            @"resume",
            @"return",
            @"linksection",
            @"struct",
            @"suspend",
            @"switch",
            @"test",
            @"threadlocal",
            @"try",
            @"union",
            @"unreachable",
            @"usingnamespace",
            @"var",
            @"volatile",
            @"while",
        };
        const res = std.meta.stringToEnum(Reserved, identifier) orelse return identifier;
        switch (res) {
            inline else => |tag| return "@\"" ++ @tagName(tag) ++ "\"",
        }
    }
};

const ParseContext = struct {
    zig: []const u8,
    cwd: std.fs.Dir,
    node: std.Progress.Node,
    transform: Transform,

    pub fn withNode(self: @This(), node: std.Progress.Node) @This() {
        var cpy = self;
        cpy.node = node;
        return cpy;
    }
};

pub const Ast = struct {
    pub const Value = union(enum) {
        none: void,
        int: u64,
        left_bshift: struct { lv: u64, rv: u64 },
        bitwise_or: struct { lv: u64, rv: u64 },

        pub fn intValue(self: @This(), T: type) !T {
            return switch (self) {
                .none => error.ValueIsNotAInt,
                .int => |v| @intCast(v),
                .left_bshift => |v| v.lv << @intCast(v.rv),
                .bitwise_or => |v| v.lv | v.rv,
            };
        }

        pub fn render(self: @This(), writer: anytype) !void {
            return switch (self) {
                .none => writer.writeAll("{}"),
                .int => |v| writer.print("{}", .{v}),
                .left_bshift => |v| writer.print("({} << {})", .{ v.lv, v.rv }),
                .bitwise_or => |v| writer.print("({} | {})", .{ v.lv, v.rv }),
            };
        }
    };

    const BuilderContext = struct {
        pub const Field = struct {
            id: ?ClangAst.Id = null,
            name: ?[]const u8 = null,
            value: Value = .none,
            comment: ?[]const u8 = null,
        };

        fields: std.ArrayListUnmanaged(Field) = .{},
        current: *Field,
        max_value: ?u64 = null,

        lut: std.AutoHashMapUnmanaged(ClangAst.Id, Value) = .{},

        pub fn nextValue(self: *@This()) Value {
            if (self.max_value) |mv| return .{ .int = mv + 1 };
            return .{ .int = 0 };
        }

        pub fn finalizeOne(self: *@This(), allocator: std.mem.Allocator) !void {
            const id = self.current.id orelse return error.InvalidClangAst;
            try self.fields.append(allocator, self.current.*);
            if (self.max_value) |mv| {
                self.max_value = @max(try self.current.value.intValue(u64), mv);
            } else {
                self.max_value = try self.current.value.intValue(u64);
            }
            try self.lut.putNoClobber(allocator, id, self.current.value);
            self.current.* = .{};
        }

        pub fn discardOne(self: *@This()) void {
            self.current.* = .{};
        }

        pub fn finish(self: *@This(), allocator: std.mem.Allocator) ![]const Field {
            self.current.* = .{};
            self.max_value = 0;
            self.lut.clearAndFree(allocator);
            return self.fields.toOwnedSlice(allocator);
        }
    };

    pub const Enum = struct {
        pub const Field = struct {
            name: []const u8,
            comment: ?[]const u8,
            value: Value,
            decl: bool,
        };

        name: []const u8,
        fields: []const Field,

        pub fn init(allocator: std.mem.Allocator, name: []const u8, src: []const BuilderContext.Field, transform: Transform) !@This() {
            var dst: std.ArrayListUnmanaged(Field) = try .initCapacity(allocator, src.len);
            errdefer dst.deinit(allocator);
            for (src) |field| {
                _ = try field.value.intValue(u64);
                const field_name = field.name orelse return error.InvalidBuilderContext;
                try dst.append(allocator, .{
                    .name = try transform.process(
                        allocator,
                        field_name,
                        .{ .kind = .field_name },
                    ),
                    .comment = field.comment,
                    .value = field.value,
                    .decl = transform.isForcedDecl(field_name),
                });
            }
            if (dst.items.len > 0) {
                // find common prefix and remove it
                var iter = std.mem.tokenizeScalar(u8, dst.items[0].name, '_');
                var prefix: ?[]const u8 = null;
                D: while (iter.peek()) |tok| {
                    const off = iter.index + tok.len;
                    if (dst.items[0].name.len <= off) break :D;
                    const needle = dst.items[0].name[0 .. off + 1];
                    for (dst.items) |field| {
                        if (!std.mem.startsWith(u8, field.name, needle)) break :D;
                    }
                    prefix = needle;
                    _ = iter.next();
                }
                if (prefix) |pfx| for (dst.items) |*field| {
                    field.name = Transform.removePrefix(field.name, pfx);
                    field.name = Transform.renameReserved(field.name);
                };
            }
            return .{
                .name = try transform.process(allocator, name, .{ .kind = .type_name }),
                .fields = try dst.toOwnedSlice(allocator),
            };
        }
    };

    enums: std.ArrayListUnmanaged(Enum) = .{},

    fn clangNodeToInt(ast: ClangAst, T: type, base: u8, b: *BuilderContext) !T {
        if (ast.referencedDecl) |decl| {
            const value = b.lut.get(decl.id) orelse return error.ClangAstInvalidReference;
            return value.intValue(T);
        }
        const value = ast.value orelse return error.ClangAstHasNoValue;
        return std.fmt.parseInt(T, value.str, base);
    }

    fn buildFromClangInner(self: *@This(), arena: std.mem.Allocator, ctx: *ParseContext, ast: ClangAst, b: *BuilderContext) !void {
        var should_finalize: bool = false;
        defer ctx.node.completeOne();
        switch (ast.kind) {
            .EnumConstantDecl => {
                const name = ast.name orelse return error.InvalidClangAst;
                b.current.id = ast.id;
                b.current.name = name;
                b.current.value = b.nextValue();
                should_finalize = true;
            },
            .ParagraphComment => {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                defer buf.deinit(arena);
                if (ast.inner) |children| for (children) |child| {
                    if (child.kind != .TextComment) continue;
                    const text = child.text orelse continue;
                    const trimmed = std.mem.trim(u8, text, &std.ascii.whitespace);
                    if (buf.items.len > 0) try buf.append(arena, ' ');
                    try buf.appendSlice(arena, trimmed);
                };
                if (!ctx.transform.isExcluded(buf.items)) {
                    b.current.comment = try buf.toOwnedSlice(arena);
                } else {
                    b.current.comment = null;
                }
            },
            .TextComment => if (ast.text) |text| {
                const trimmed = std.mem.trim(u8, text, &std.ascii.whitespace);
                if (!ctx.transform.isExcluded(trimmed)) {
                    b.current.comment = std.mem.trim(u8, trimmed, &std.ascii.whitespace);
                } else {
                    b.current.comment = null;
                }
            },
            .IntegerLiteral => {
                // TODO: preserve textual format
                b.current.value = .{ .int = try clangNodeToInt(ast, u64, 10, b) };
            },
            .ParenExpr => {
                if (ast.inner) |children| for (children) |child| {
                    switch (child.kind) {
                        .BinaryOperator => {
                            switch (child.opcode) {
                                .@"<<" => {
                                    const values = child.inner orelse return error.InvalidClangAst;
                                    b.current.value = .{
                                        .left_bshift = .{
                                            .lv = try clangNodeToInt(values[0], u64, 10, b),
                                            .rv = try clangNodeToInt(values[1], u64, 10, b),
                                        },
                                    };
                                },
                                .@"|" => {
                                    const values = child.inner orelse return error.InvalidClangAst;
                                    b.current.value = .{
                                        .bitwise_or = .{
                                            .lv = try clangNodeToInt(values[0], u64, 10, b),
                                            .rv = try clangNodeToInt(values[1], u64, 10, b),
                                        },
                                    };
                                },
                                else => {
                                    root.log.warn("fixme: binaryop: {s}", .{@tagName(child.opcode)});
                                },
                            }
                        },
                        // TODO: should handle other kind of operations as well
                        else => {},
                    }
                };
            },
            else => {},
        }

        switch (ast.kind) {
            .ParagraphComment => {},
            .ParenExpr => {},
            else => if (ast.inner) |children| for (children) |child| {
                try self.buildFromClangInner(arena, ctx, child, b);
            },
        }

        if (should_finalize) {
            if (b.current.name) |name| {
                if (ctx.transform.isExcluded(name)) {
                    b.discardOne();
                } else {
                    try b.finalizeOne(arena);
                }
            }
        }
    }

    fn buildFromClang(self: *@This(), arena: std.mem.Allocator, ctx: *ParseContext, ast: ClangAst, b: *BuilderContext) !void {
        if (ast.inner) |children| for (children) |child| {
            try self.buildFromClangInner(arena, ctx, child, b);
        };
    }

    fn parseClangInner(self: *@This(), arena: std.mem.Allocator, ctx: *ParseContext, ast: ClangAst) !void {
        defer ctx.node.completeOne();
        switch (ast.kind) {
            .EnumDecl => {
                const name: []const u8 = ast.name orelse D: {
                    const file = ast.loc.root.file orelse return;
                    if (file[0] == '/') return;
                    if (ctx.transform.name()) |renamed| break :D renamed;
                    root.log.warn("found anonymous enum ({}) in: {s}", .{ ctx.transform.num_anon, file });
                    return;
                };
                if (ctx.transform.isExcluded(name)) return;
                var field: BuilderContext.Field = .{};
                var builder: BuilderContext = .{ .current = &field };
                try self.buildFromClang(arena, ctx, ast, &builder);
                try self.enums.append(arena, try .init(arena, name, try builder.finish(arena), ctx.transform));
            },
            else => if (ast.inner) |children| for (children) |child| {
                try self.parseClangInner(arena, ctx, child);
            },
        }
    }

    fn parseClang(arena: std.mem.Allocator, ctx: ParseContext, ast: ClangAst) !@This() {
        var node = ctx.node.start("ast::parse", ast.countNodes());
        defer node.end();
        defer node.completeOne();
        var self: @This() = .{};
        var mut_ctx = ctx.withNode(node);
        if (ast.inner) |children| for (children) |child| {
            try self.parseClangInner(arena, &mut_ctx, child);
        };
        return self;
    }

    pub fn parse(arena: std.mem.Allocator, ctx: ParseContext, paths: []const []const u8) !@This() {
        var sub_arena: std.heap.ArenaAllocator = .init(arena);
        defer sub_arena.deinit();
        return .parseClang(arena, ctx, try .parse(sub_arena.allocator(), ctx, paths));
    }
};

const ClangAst = struct {
    pub const Id = enum(u64) {
        _,

        pub fn jsonParse(_: std.mem.Allocator, source: anytype, _: std.json.ParseOptions) !@This() {
            return switch (try source.next()) {
                .string => |str| return @enumFromInt(try std.fmt.parseInt(u64, str[2..], 16)),
                else => error.SyntaxError,
            };
        }
    };

    pub const Kind = enum {
        EnumDecl,
        EnumConstantDecl,
        IntegerLiteral,
        ParenExpr,
        BinaryOperator,
        ParagraphComment,
        TextComment,
        unknown,

        pub fn jsonParse(_: std.mem.Allocator, source: anytype, _: std.json.ParseOptions) !@This() {
            return switch (try source.next()) {
                .string => |str| std.meta.stringToEnum(@This(), str) orelse .unknown,
                else => error.SyntaxError,
            };
        }
    };

    pub const Location = struct {
        const Root = struct {
            offset: u32 = 0,
            file: ?[]const u8 = null,
            line: u32 = 0,
            presumedLine: ?u32 = null,
            col: u32 = 0,
            tokLen: u16 = 0,
            includedFrom: ?struct {
                file: []const u8,
            } = null,
            isMacroArgExpansion: bool = false,
        };

        spellingLoc: ?Root = null,
        expansionLoc: ?Root = null,
        root: Root = .{},

        pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, opts: std.json.ParseOptions) !@This() {
            const tok = try source.next();
            if (tok != .object_begin) return error.SyntaxError;
            var self: @This() = .{};
            next: while (true) switch (try source.next()) {
                .string => |str| {
                    inline for (std.meta.fields(@This())) |field| {
                        if (std.mem.eql(u8, field.name, str)) {
                            @field(self, field.name) = try std.json.innerParse(field.type, allocator, source, opts);
                            continue :next;
                        }
                    }
                    inline for (std.meta.fields(Root)) |field| {
                        if (std.mem.eql(u8, field.name, str)) {
                            @field(self.root, field.name) = try std.json.innerParse(field.type, allocator, source, opts);
                            continue :next;
                        }
                    }
                },
                .object_end => return self,
                else => break :next,
            };
            return error.SyntaxError;
        }
    };

    pub const Type = struct {
        qualType: []const u8,
        desugaredQualType: ?[]const u8 = null,
        typeAliasDeclId: ?Id = null,
    };

    pub const Decl = struct {
        id: Id,
        kind: Kind,
        name: []const u8,
        type: ?Type = null,
    };

    pub const Value = struct {
        str: []const u8,

        pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, _: std.json.ParseOptions) !@This() {
            return switch (try source.nextAlloc(allocator, .alloc_if_needed)) {
                .number, .string, .allocated_string => |str| .{ .str = str },
                .true => .{ .str = "1" },
                .false => .{ .str = "0" },
                else => |tag| D: {
                    root.log.err("{}", .{tag});
                    break :D error.SyntaxError;
                },
            };
        }
    };

    id: Id = @enumFromInt(0),
    kind: Kind = .unknown,
    loc: Location = .{},
    range: struct {
        begin: Location = .{},
        end: Location = .{},
    } = .{},
    isImplicit: bool = false,
    isReferenced: bool = false,
    implicit: bool = false,
    inherited: bool = false,
    @"inline": bool = false,
    name: ?[]const u8 = null,
    closeName: ?[]const u8 = null,
    direction: enum { none, in, out } = .none,
    explicit: ?bool = null,
    param: ?[]const u8 = null,
    paramIdx: ?u32 = null,
    nonOdrUseReason: enum { none, unevaluated } = .none,
    isArrow: bool = false,
    renderKind: enum { none, normal, emphasized } = .none,
    args: ?[]const []const u8 = null,
    mangledName: ?[]const u8 = null,
    storageClass: enum { auto, @"extern", static } = .auto,
    variadic: bool = false,
    hasElse: bool = false,
    canOverflow: ?bool = null,
    isUsed: bool = false,
    type: ?Type = null,
    argType: ?Type = null,
    computeLHSType: ?Type = null,
    computeResultType: ?Type = null,
    cc: enum { none, cdecl } = .none,
    qualifiers: enum { none, @"volatile", @"const" } = .none,
    decl: ?Decl = null,
    ownedTagDecl: ?Decl = null,
    referencedDecl: ?Decl = null,
    previousDecl: ?Id = null,
    parentDeclContextId: ?Id = null,
    referencedMemberDecl: ?Id = null,
    text: ?[]const u8 = null,
    size: ?u64 = null,
    valueCategory: enum { none, prvalue, lvalue } = .none,
    castKind: ?[]const u8 = null,
    isPartOfExplicitCast: bool = false,
    isBitfield: bool = false,
    isPostfix: bool = false,
    opcode: enum {
        none,
        @"!",
        @"-",
        @"+",
        @"*",
        @"%",
        @"^",
        @"|",
        @"&",
        @"||",
        @"<<",
        @">>",
        @"&&",
        @"<",
        @"<=",
        @">",
        @">=",
        @"!=",
        @"==",
        @"=",
        @"+=",
        @"-=",
        @"/=",
        @"*=",
        @"|=",
        @"&=",
        @"++",
        @"--",
        @",",
    } = .none,
    value: ?Value = null,
    tagUsed: ?[]const u8 = null,
    completeDefinition: bool = false,
    message: ?[]const u8 = null,
    init: ?[]const u8 = null,
    inner: ?[]const @This() = null,

    fn countNodesInner(self: @This(), num: usize) usize {
        var new_num = num + 1;
        if (self.inner) |children| for (children) |child| {
            new_num += child.countNodesInner(num + 1);
        };
        return new_num;
    }

    pub fn countNodes(self: @This()) usize {
        return self.countNodesInner(0);
    }

    fn dumpAstJson(allocator: std.mem.Allocator, ctx: ParseContext, paths: []const []const u8) ![]const u8 {
        var arena: std.heap.ArenaAllocator = .init(allocator);
        defer arena.deinit();

        // zig fmt: off
        var child: std.process.Child = .init(&.{
            ctx.zig, "cc", "-E", "-xc", "-I.", "-Xclang", "-ast-dump=json", "-"
        }, arena.allocator());
        // zig fmt: on

        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        child.progress_node = ctx.node;
        child.cwd_dir = ctx.cwd;
        try child.spawn();
        try child.waitForSpawn();
        errdefer _ = child.kill() catch {};

        {
            var stdin = child.stdin orelse {
                root.log.err("failed to pipe stdin", .{});
                return error.ClangAstDumpFailed;
            };
            defer stdin.close();
            defer child.stdin = null;
            for (paths) |path| try stdin.writer().print("#include \"{s}\"\n", .{path});
        }

        const mib_in_bytes = 1048576;
        var stdout: std.ArrayListUnmanaged(u8) = .empty;
        var stderr: std.ArrayListUnmanaged(u8) = .empty;
        try child.collectOutput(arena.allocator(), &stdout, &stderr, 64 * mib_in_bytes);

        const term = try child.wait();
        if (term.Exited != 0) {
            root.log.err("{s}", .{stderr.items});
            return error.ClangAstDumpFailed;
        }

        return allocator.dupe(u8, stdout.items);
    }

    const PrettyOptions = struct {
        lines_before: usize = 6,
        lines_after: usize = 6,
    };

    const Diagnostics = struct {
        left_pad: usize,
        json: std.json.Diagnostics,
    };

    fn formatDiagnostics(diags: Diagnostics, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        for (0..diags.left_pad) |_| try writer.writeAll(" ");
        try writer.writeAll("^");
        const width = (diags.json.getByteOffset() - diags.json.line_start_cursor) -| (diags.left_pad +| 2);
        for (0..width) |_| try writer.writeAll("~");
    }

    fn dumpPrettyDiagnostics(json: []const u8, diags: std.json.Diagnostics, opts: PrettyOptions) void {
        var lines = std.mem.tokenizeAny(u8, json, "\r\n");
        var cursor: usize = 1;
        while (lines.next()) |line| {
            defer cursor += 1;
            if (cursor < diags.getLine() -| opts.lines_before) continue;
            if (cursor > diags.getLine() +| opts.lines_after) break;
            root.log.err("{s}", .{line});
            if (cursor != diags.getLine()) continue;
            var left_pad: usize = 0;
            for (line) |c| switch (c) {
                ' ' => left_pad += 1,
                else => break,
            };
            root.log.err("{}", .{std.fmt.Formatter(formatDiagnostics){ .data = .{ .left_pad = left_pad, .json = diags } }});
        }
        const problem = std.mem.trim(u8, json[diags.line_start_cursor..diags.getByteOffset()], &std.ascii.whitespace);
        root.log.err("{}:{}: {s}", .{ diags.getLine(), diags.getColumn(), problem });
    }

    pub fn parse(arena: std.mem.Allocator, ctx: ParseContext, paths: []const []const u8) !@This() {
        var node = ctx.node.start("ast::clang::dump", paths.len);
        defer node.end();
        defer node.setCompletedItems(paths.len);
        const json = try dumpAstJson(arena, ctx.withNode(node), paths);
        var scanner: std.json.Scanner = .initCompleteInput(arena, json);
        defer scanner.deinit();
        var diags: std.json.Diagnostics = .{};
        errdefer dumpPrettyDiagnostics(json, diags, .{});
        scanner.enableDiagnostics(&diags);
        return std.json.parseFromTokenSourceLeaky(@This(), arena, &scanner, .{});
    }
};
