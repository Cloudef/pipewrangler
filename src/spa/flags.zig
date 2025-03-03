pub const Param = packed struct(u32) {
    serial: bool,
    read: bool,
    write: bool,
    _: u29,
};

pub const Alloc = packed struct(u32) {
    /// add metadata data in the skeleton
    inline_meta: bool,
    /// add chunk data in the skeleton
    inline_chunk: bool,
    /// add buffer data to the skeleton
    inline_data: bool,
    /// don't set data pointers
    no_data: bool,

    pub const all: @This() = .{
        .inline_meta = true,
        .inline_chunk = true,
        .inline_data = true,
        .no_data = false,
    };
};

pub const Chunk = packed struct(u32) {
    /// chunk data is corrupted in some way
    corrupted: bool,
    /// chunk data is empty with media specific neutral data such as silence or black
    empty: bool,
};

pub const Data = packed struct(u32) {
    /// data is readable
    readable: bool,
    /// data is writable
    writable: bool,
    /// data pointer can be changed
    dynamic: bool,
    /// data is mappable with simple mmap/munmap
    mappable: bool,
    _: u28,

    pub fn canReadWrite(self: @This()) bool {
        return self.readable and self.writable;
    }
};

pub const MetaHeader = packed struct(u32) {
    /// data is not continuous with previous buffer
    discont: bool,
    /// data might be corrupted
    corrupted: bool,
    /// media specific marker
    marker: bool,
    /// data contains a codec specific header
    header: bool,
    /// data contains media neutral data
    gap: bool,
    /// cannot be decoded independently
    delta_unit: bool,
};

pub const Permission = packed struct(u32) {
    _0: u2,
    metadata: bool,
    link: bool,
    _1: u2,
    exec: bool,
    write: bool,
    read: bool,
    _2: u23,
};

pub const Audio = packed struct(u32) {
    unpositioned: bool,
    _: u31,
};
