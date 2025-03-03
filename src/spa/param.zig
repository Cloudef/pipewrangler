const wire = @import("generated/spa.zig");
const flags = @import("flags.zig");
const pod = @import("pod.zig");

pub const PropInfo = union(wire.PropInfo) {
    id: wire.Prop,
    name: [:0]const u8,
    type: pod.Pod,
    labels: pod.types.Struct,
    container: pod.types.Id,
    params: u32,
    description: [:0]const u8,
};

pub const Prop = union(wire.Prop) {
    unknown: void,
    device: [:0]const u8,
    device_name: [:0]const u8,
    device_fd: pod.types.Fd,
    card: [:0]const u8,
    card_name: [:0]const u8,
    min_latency: u32,
    max_latency: u32,
    periods: u32,
    period_size: u32,
    period_event: bool,
    live: bool,
    rate: f64,
    quality: u32,
    bluetooth_audio_codec: wire.BluetoothAudioCodec,
    bluetooth_offload_active: bool,
    wave_type: pod.types.Id,
    frequency: u32,
    volume: f32,
    mute: bool,
    pattern_type: pod.types.Id,
    dither_type: pod.types.Id,
    truncate: bool,
    channel_volumes: []const f32,
    volume_base: f32,
    volume_step: f32,
    channel_map: []const wire.AudioChannel,
    monitor_mute: bool,
    monitor_volumes: []const f32,
    latency_offset_nsec: u64,
    soft_mute: bool,
    soft_volumes: []const f32,
    iec958_codecs: []const wire.AudioIec958Codec,
    volume_ramp_samples: u32,
    volume_ramp_step_samples: u32,
    volume_ramp_time: u32,
    volume_ramp_step_time: u32,
    volume_ramp_scale: wire.AudioVolumeRampScale,
    brightness: f32,
    contrast: f32,
    saturation: f32,
    hue: u32,
    gamma: u32,
    exposure: u32,
    gain: f32,
    sharpness: f32,
    params: pod.types.Struct,
};

pub const Format = union(wire.Format) {
    media_type: wire.MediaType,
    media_subtype: wire.MediaSubtype,
    audio_format: wire.AudioFormat,
    audio_flags: flags.Audio,
    audio_rate: u32,
    audio_channels: u32,
    audio_position: []const wire.AudioChannel,
    audio_iec958_codec: wire.AudioIec958Codec,
    audio_bitorder: wire.ParamBitorder,
    audio_interleave: u32,
    audio_bitrate: u32,
    audio_block_align: u32,
    audio_aac_stream_format: wire.AudioAacStreamFormat,
    audio_wma_profile: wire.AudioWmaProfile,
    audio_amr_band_mode: wire.AudioAmrBandMode,
    video_format: wire.VideoFormat,
    video_modifier: u64,
    video_size: pod.types.Rectangle,
    video_framerate: pod.types.Fraction,
    video_max_framerate: pod.types.Fraction,
    video_views: u32,
    video_interlace_mode: wire.VideoInterlaceMode,
    video_pixel_aspect_ratio: pod.types.Fraction,
    video_multiview_mode: wire.VideoMultiviewMode,
    video_multiview_flags: wire.VideoMultiviewFlags,
    video_chroma_site: wire.VideoChromaSite,
    video_color_range: wire.VideoColorRange,
    video_color_matrix: wire.VideoColorMatrix,
    video_transfer_function: wire.VideoTransferFunction,
    video_color_primaries: wire.VideoColorPrimaries,
    video_profile: u32,
    video_level: u32,
    video_h264_stream_format: wire.H264StreamFormat,
    video_h264_alignment: wire.H264Alignment,
    control_types: wire.ControlType,
};

pub const Buffers = union(wire.ParamBuffers) {
    buffers: u32,
    blocks: u32,
    size: u32,
    stride: u32,
    @"align": u32,
    data_type: wire.DataType,
    meta_type: wire.MetaType,
};

pub const Meta = union(wire.ParamMeta) {
    type: wire.MetaType,
    size: u32,
};

pub const Io = union(wire.ParamIo) {
    id: wire.IoType,
    size: u32,
};

pub const Profile = union(wire.ParamProfile) {
    index: u32,
    name: [:0]const u8,
    description: [:0]const u8,
    priority: u32,
    available: wire.ParamAvailability,
    info: pod.types.Struct,
    classes: pod.types.Struct,
    save: bool,
};

pub const PortConfig = union(wire.ParamPortConfig) {
    direction: wire.Direction,
    mode: wire.ParamPortConfigMode,
    monitor: bool,
    control: bool,
    format: pod.types.Object,
};

pub const Route = union(wire.ParamRoute) {
    index: u32,
    direction: wire.Direction,
    device: u32,
    name: [:0]const u8,
    description: [:0]const u8,
    priority: u32,
    available: wire.ParamAvailability,
    info: pod.types.Struct,
    profiles: []const u32,
    props: pod.types.Object,
    devices: []const u32,
    profile: u32,
    save: bool,
};

pub const Latency = union(wire.ParamLatency) {
    direction: wire.Direction,
    min_quantum: f32,
    max_quantum: f32,
    min_rate: u32,
    max_rate: u32,
    min_ns: u64,
    max_ns: u64,
};

pub const ProcessLatency = union(wire.ParamProcessLatency) {
    quantum: f32,
    rate: u32,
    ns: u64,
};

pub const Tag = union(wire.ParamTag) {
    direction: wire.Direction,
    info: pod.types.Struct,
};
