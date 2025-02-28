pub const Format = enum(u32) {
    unknown,
    encoded,

    // interleaved formats
    s8 = 0x101,
    u8,
    s16_le,
    s16_be,
    u16_le,
    u16_be,
    s24_32_le,
    s24_32_be,
    u24_32_le,
    u24_32_be,
    s32_le,
    s32_be,
    u32_le,
    u32_be,
    s24_le,
    s24_be,
    u24_le,
    u24_be,
    s20_le,
    s20_be,
    u20_le,
    u20_be,
    s18_le,
    s18_be,
    u18_le,
    u18_be,
    f32_le,
    f32_be,
    f64_le,
    f64_be,

    ulaw,
    alaw,

    // planar formats
    u8p = 0x201,
    s16p,
    s24_32p,
    s32p,
    s24p,
    f32p,
    f64p,
    s8p,

    _reserved = 0x400,

    // other formats
    _,
};

pub const Channel = enum(u32) {
    unknown,
    na,

    mono,

    fl,
    fr,
    fc,
    lfe,
    sl,
    sr,
    flc,
    frc,
    rc,
    rl,
    rr,
    tc,
    tfl,
    tfc,
    tfr,
    trl,
    trc,
    trr,
    rlc,
    rrc,
    flw,
    frw,
    lfe2,
    flh,
    fch,
    frh,
    tflc,
    tfrc,
    tsl,
    tsr,
    llfe,
    rlfe,
    bc,
    blc,
    brc,

    // aux channels
    aux0 = 0x1000,
    aux1,
    aux2,
    aux3,
    aux4,
    aux5,
    aux6,
    aux7,
    aux8,
    aux9,
    aux10,
    aux11,
    aux12,
    aux13,
    aux14,
    aux15,
    aux16,
    aux17,
    aux18,
    aux19,
    aux20,
    aux21,
    aux22,
    aux23,
    aux24,
    aux25,
    aux26,
    aux27,
    aux28,
    aux29,
    aux30,
    aux31,
    aux32,
    aux33,
    aux34,
    aux35,
    aux36,
    aux37,
    aux38,
    aux39,
    aux40,
    aux41,
    aux42,
    aux43,
    aux44,
    aux45,
    aux46,
    aux47,
    aux48,
    aux49,
    aux50,
    aux51,
    aux52,
    aux53,
    aux54,
    aux55,
    aux56,
    aux57,
    aux58,
    aux59,
    aux60,
    aux61,
    aux62,
    aux63,

    _reserved = 0x10000,

    // custom channels
    _,
};

pub const VolumeRampScale = enum {
    invalid,
    linear,
    cubic,
};

pub const Flags = packed struct(u32) {
    unpositioned: bool,
    _: u31,
};

pub const Iec958Codec = enum(u32) {
    unknown,
    pcm,
    dts,
    ac3,
    mpeg,
    mpeg2_aac,
    eac3,
    truehd,
    dtshd,
};

pub const BluetoothCodec = enum(u32) {
    // A2DP
    sbc,
    sbc_xq,
    mpeg,
    aac,
    aac_eld,
    aptx,
    aptx_hd,
    ldac,
    aptx_ll,
    aptx_ll_duplex,
    faststream,
    faststream_duplex,
    lc3plus_hr,
    opus_05,
    opus_05_51,
    opus_05_71,
    opus_05_duplex,
    opus_05_pro,
    opus_g,

    // HFP
    cvsd = 0x100,
    msbc,
    lc3_swb,

    // BAP
    lc3 = 0x200,

    // ASHA
    g722 = 0x300,
};
