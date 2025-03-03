pub const Direction = enum(u32) {
    in = 0x0,
    out,
};

pub const TypeId = enum(u32) {
    none = 0x1,
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
    pointer_buffer = 0x10001,
    pointer_meta,
    pointer_dict,
    event_device = 0x20001,
    event_node,
    command_device = 0x30001,
    command_node,
    object_prop_info = 0x40001,
    object_props,
    object_media_format,
    object_param_buffers,
    object_param_meta,
    object_param_io,
    object_param_profile,
    object_param_port_config,
    object_param_route,
    object_profiler,
    object_param_latency,
    object_param_process_latency,
    object_param_tag,
    pub const start = 0x0;
    /// not part of ABI
    pub const last = 0x15;
    pub const pointer_start = 0x10000;
    /// not part of ABI
    pub const pointer_last = 0x10004;
    pub const event_start = 0x20000;
    /// not part of ABI
    pub const event_last = 0x20003;
    pub const command_start = 0x30000;
    /// not part of ABI
    pub const command_last = 0x30003;
    pub const object_start = 0x40000;
    /// not part of ABI
    pub const object_last = 0x4000e;
    pub const vendor_pipe_wire = 0x2000000;
    pub const vendor_other = 0x7f000000;
};

pub const ChoiceType = enum(u32) {
    /// no choice, first value is current
    none = 0x0,
    /// range: default, min, max
    range,
    /// range with step: default, min, max, step
    step,
    /// list: default, alternative,...
    @"enum",
    /// flags: default, possible flags,...
    flags,
};

pub const DbusType = enum(u32) {
    /// The login session bus
    session = 0x0,
    /// The systemwide bus
    system,
    /// The bus that started us, if any
    starter,
};

pub const LogLevel = enum(u32) {
    none = 0x0,
    @"error",
    warn,
    info,
    debug,
    trace,
};

pub const ParamType = enum(u32) {
    /// invalid
    invalid = 0x0,
    /// property information as SPA_TYPE_OBJECT_PropInfo
    prop_info,
    /// properties as SPA_TYPE_OBJECT_Props
    props,
    /// available formats as SPA_TYPE_OBJECT_Format
    enum_media_format,
    /// configured format as SPA_TYPE_OBJECT_Format
    media_format,
    /// buffer configurations as SPA_TYPE_OBJECT_ParamBuffers
    buffers,
    /// allowed metadata for buffers as SPA_TYPE_OBJECT_ParamMeta
    meta,
    /// configurable IO areas as SPA_TYPE_OBJECT_ParamIO
    io,
    /// profile enumeration as SPA_TYPE_OBJECT_ParamProfile
    enum_profile,
    /// profile configuration as SPA_TYPE_OBJECT_ParamProfile
    profile,
    /// port configuration enumeration as SPA_TYPE_OBJECT_ParamPortConfig
    enum_port_config,
    /// port configuration as SPA_TYPE_OBJECT_ParamPortConfig
    port_config,
    /// routing enumeration as SPA_TYPE_OBJECT_ParamRoute
    enum_route,
    /// routing configuration as SPA_TYPE_OBJECT_ParamRoute
    route,
    /// Control parameter, a SPA_TYPE_Sequence
    control,
    /// latency reporting, a SPA_TYPE_OBJECT_ParamLatency
    latency,
    /// processing latency, a SPA_TYPE_OBJECT_ParamProcessLatency
    process_latency,
    /// tag reporting, a SPA_TYPE_OBJECT_ParamTag. Since 0.3.79
    tag,
};

pub const ParamBitorder = enum(u32) {
    /// unknown bitorder
    unknown = 0x0,
    /// most significant bit
    msb,
    /// least significant bit
    lsb,
};

pub const ParamAvailability = enum(u32) {
    /// unknown availability
    unknown = 0x0,
    /// not available
    no,
    /// available
    yes,
};

pub const ParamProfile = enum(u32) {
    /// profile index (Int)
    index = 0x1,
    /// profile name (String)
    name,
    /// profile description (String)
    description,
    /// profile priority (Int)
    priority,
    /// availability of the profile (Id enum spa_param_availability)
    available,
    /// info (Struct( Int : n_items, (String : key, String : value)*))
    info,
    /// node classes provided by this profile (Struct( Int : number of items following Struct( String : class name (eg. "Audio/Source"), Int : number of nodes String : property (eg. "card.profile.devices"), Array of Int: device indexes )*))
    classes,
    /// If profile should be saved (Bool)
    save,
    /// properties for SPA_TYPE_OBJECT_ParamProfile
    pub const start = 0x0;
};

pub const ParamPortConfigMode = enum(u32) {
    /// no configuration
    none = 0x0,
    /// passthrough configuration
    passthrough,
    /// convert configuration
    convert,
    /// dsp configuration, depending on the external format. For audio, ports will be configured for the given number of channels with F32 format.
    dsp,
};

pub const ParamPortConfig = enum(u32) {
    /// (Id enum spa_direction) direction
    direction = 0x1,
    /// (Id enum spa_param_port_config_mode) mode
    mode,
    /// (Bool) enable monitor output ports on input ports
    monitor,
    /// (Bool) enable control ports
    control,
    /// (Object) format filter
    format,
    /// properties for SPA_TYPE_OBJECT_ParamPortConfig
    pub const start = 0x0;
};

pub const ParamRoute = enum(u32) {
    /// index of the routing destination (Int)
    index = 0x1,
    /// direction, input/output (Id enum spa_direction)
    direction,
    /// device id (Int)
    device,
    /// name of the routing destination (String)
    name,
    /// description of the destination (String)
    description,
    /// priority of the destination (Int)
    priority,
    /// availability of the destination (Id enum spa_param_availability)
    available,
    /// info (Struct( Int : n_items, (String : key, String : value)*))
    info,
    /// associated profile indexes (Array of Int)
    profiles,
    /// properties SPA_TYPE_OBJECT_Props
    props,
    /// associated device indexes (Array of Int)
    devices,
    /// profile id (Int)
    profile,
    /// If route should be saved (Bool)
    save,
    /// properties for SPA_TYPE_OBJECT_ParamRoute
    pub const start = 0x0;
};

pub const ParamBuffers = enum(u32) {
    /// number of buffers (Int)
    buffers = 0x1,
    /// number of data blocks per buffer (Int)
    blocks,
    /// size of a data block memory (Int)
    size,
    /// stride of data block memory (Int)
    stride,
    /// alignment of data block memory (Int)
    @"align",
    /// possible memory types (flags choice Int, mask of enum spa_data_type)
    data_type,
    /// required meta data types (Int, mask of enum spa_meta_type)
    meta_type,
    /// properties for SPA_TYPE_OBJECT_ParamBuffers
    pub const start = 0x0;
};

pub const ParamMeta = enum(u32) {
    /// the metadata, one of enum spa_meta_type (Id enum spa_meta_type)
    type = 0x1,
    /// the expected maximum size the meta (Int)
    size,
    /// properties for SPA_TYPE_OBJECT_ParamMeta
    pub const start = 0x0;
};

pub const ParamIo = enum(u32) {
    /// type ID, uniquely identifies the io area (Id enum spa_io_type)
    id = 0x1,
    /// size of the io area (Int)
    size,
    /// properties for SPA_TYPE_OBJECT_ParamIO
    pub const start = 0x0;
};

pub const MediaType = enum(u32) {
    /// media type for SPA_TYPE_OBJECT_Format
    unknown = 0x0,
    audio,
    video,
    image,
    binary,
    stream,
    application,
};

pub const MediaSubtype = enum(u32) {
    /// media subtype for SPA_TYPE_OBJECT_Format
    unknown = 0x0,
    raw,
    dsp,
    iec958,
    /// S/PDIF
    dsd,
    /// S/PDIF
    mp3 = 0x10001,
    /// S/PDIF
    aac,
    /// S/PDIF
    vorbis,
    /// S/PDIF
    wma,
    /// S/PDIF
    ra,
    /// S/PDIF
    sbc,
    /// S/PDIF
    adpcm,
    /// S/PDIF
    g723,
    /// S/PDIF
    g726,
    /// S/PDIF
    g729,
    /// S/PDIF
    amr,
    /// S/PDIF
    gsm,
    /// S/PDIF
    alac,
    /// since 0.3.65
    flac,
    /// since 0.3.65
    ape,
    /// since 0.3.65
    opus,
    /// since 0.3.68
    h264 = 0x20001,
    /// since 0.3.68
    mjpg,
    /// since 0.3.68
    dv,
    /// since 0.3.68
    mpegts,
    /// since 0.3.68
    h263,
    /// since 0.3.68
    mpeg1,
    /// since 0.3.68
    mpeg2,
    /// since 0.3.68
    mpeg4,
    /// since 0.3.68
    xvid,
    /// since 0.3.68
    vc1,
    /// since 0.3.68
    vp8,
    /// since 0.3.68
    vp9,
    /// since 0.3.68
    bayer,
    /// since 0.3.68
    jpeg = 0x30001,
    /// since 0.3.68
    midi = 0x50001,
    /// control stream, data contains spa_pod_sequence with control info.
    control = 0x60001,
    /// S/PDIF
    pub const start_audio = 0x10000;
    /// since 0.3.68
    pub const start_video = 0x20000;
    /// since 0.3.68
    pub const start_image = 0x30000;
    /// since 0.3.68
    pub const start_binary = 0x40000;
    /// since 0.3.68
    pub const start_stream = 0x50000;
    /// since 0.3.68
    pub const start_application = 0x60000;
};

pub const Format = enum(u32) {
    /// media type (Id enum spa_media_type)
    media_type = 0x1,
    /// media subtype (Id enum spa_media_subtype)
    media_subtype,
    /// audio format, (Id enum spa_audio_format)
    audio_format = 0x10001,
    /// optional flags (Int)
    audio_flags,
    /// sample rate (Int)
    audio_rate,
    /// number of audio channels (Int)
    audio_channels,
    /// channel positions (Id enum spa_audio_position)
    audio_position,
    /// codec used (IEC958) (Id enum spa_audio_iec958_codec)
    audio_iec958_codec,
    /// bit order (Id enum spa_param_bitorder)
    audio_bitorder,
    /// Interleave bytes (Int)
    audio_interleave,
    /// bit rate (Int)
    audio_bitrate,
    /// audio data block alignment (Int)
    audio_block_align,
    /// AAC stream format, (Id enum spa_audio_aac_stream_format)
    audio_aac_stream_format,
    /// WMA profile (Id enum spa_audio_wma_profile)
    audio_wma_profile,
    /// AMR band mode (Id enum spa_audio_amr_band_mode)
    audio_amr_band_mode,
    /// video format (Id enum spa_video_format)
    video_format = 0x20001,
    /// format modifier (Long) use only with DMA-BUF and omit for other buffer types
    video_modifier,
    /// size (Rectangle)
    video_size,
    /// frame rate (Fraction)
    video_framerate,
    /// maximum frame rate (Fraction)
    video_max_framerate,
    /// number of views (Int)
    video_views,
    /// (Id enum spa_video_interlace_mode)
    video_interlace_mode,
    /// (Rectangle)
    video_pixel_aspect_ratio,
    /// (Id enum spa_video_multiview_mode)
    video_multiview_mode,
    /// (Id enum spa_video_multiview_flags)
    video_multiview_flags,
    /// /Id enum spa_video_chroma_site)
    video_chroma_site,
    /// /Id enum spa_video_color_range)
    video_color_range,
    /// /Id enum spa_video_color_matrix)
    video_color_matrix,
    /// /Id enum spa_video_transfer_function)
    video_transfer_function,
    /// /Id enum spa_video_color_primaries)
    video_color_primaries,
    /// (Int)
    video_profile,
    /// (Int)
    video_level,
    /// (Id enum spa_h264_stream_format)
    video_h264_stream_format,
    /// (Id enum spa_h264_alignment)
    video_h264_alignment,
    /// possible control types (flags choice Int, mask of enum spa_control_type)
    control_types = 0x60001,
    /// properties for audio SPA_TYPE_OBJECT_Format
    pub const start = 0x0;
    pub const start_audio = 0x10000;
    pub const start_video = 0x20000;
    pub const start_image = 0x30000;
    pub const start_binary = 0x40000;
    pub const start_stream = 0x50000;
    pub const start_application = 0x60000;
};

pub const ParamLatency = enum(u32) {
    /// direction, input/output (Id enum spa_direction)
    direction = 0x1,
    /// min latency relative to quantum (Float)
    min_quantum,
    /// max latency relative to quantum (Float)
    max_quantum,
    /// min latency (Int) relative to graph rate
    min_rate,
    /// max latency (Int) relative to graph rate
    max_rate,
    /// min latency (Long) in nanoseconds
    min_ns,
    /// max latency (Long) in nanoseconds
    max_ns,
    /// The latency values are adjusted by or SPA_PARAM_ProcessLatency, if present. (e.g. for ALSA this is used to adjust for the internal hardware latency).
    pub const start = 0x0;
};

pub const ParamProcessLatency = enum(u32) {
    /// latency relative to quantum (Float)
    quantum = 0x1,
    /// latency (Int) relative to graph rate
    rate,
    /// latency (Long) in nanoseconds
    ns,
    /// The processing latency indicates logical time delay between a sample in an input port, and a corresponding sample in an output port, relative to the graph time.
    pub const start = 0x0;
};

pub const Profiler = enum(u32) {
    /// Generic info, counter and CPU load, (Struct( Long : counter, Float : cpu_load fast, Float : cpu_load medium, Float : cpu_load slow), Int : xrun-count))
    info = 0x10001,
    /// clock information (Struct( Int : clock flags, Int : clock id, String: clock name, Long : clock nsec, Fraction : clock rate, Long : clock position, Long : clock duration, Long : clock delay, Double : clock rate_diff, Long : clock next_nsec, Int : transport_state, Int : clock cycle, Long : xrun duration))
    clock,
    /// generic driver info block (Struct( Int : driver_id, String : name, Long : driver prev_signal, Long : driver signal, Long : driver awake, Long : driver finish, Int : driver status, Fraction : latency, Int : xrun_count))
    driver_block,
    /// generic follower info block (Struct( Int : id, String : name, Long : prev_signal, Long : signal, Long : awake, Long : finish, Int : status, Fraction : latency, Int : xrun_count))
    follower_block = 0x20001,
    /// follower clock information (Struct( Int : clock id, String: clock name, Long : clock nsec, Fraction : clock rate, Long : clock position, Long : clock duration, Long : clock delay, Double : clock rate_diff, Long : clock next_nsec, Long : xrun duration))
    follower_clock,
    /// properties for SPA_TYPE_OBJECT_Profiler
    pub const start = 0x0;
    /// driver related profiler properties
    pub const start_driver = 0x10000;
    /// follower related profiler properties
    pub const start_follower = 0x20000;
    pub const start_custom = 0x1000000;
};

pub const PropInfo = enum(u32) {
    /// associated id of the property
    id = 0x1,
    /// name of the property
    name,
    /// type and range/enums of property
    type,
    /// labels of property if any, this is a struct with pairs of values, the first one is of the type of the property, the second one is a string with a user readable label for the value.
    labels,
    /// type of container if any (Id)
    container,
    /// is part of params property (Bool)
    params,
    /// User readable description
    description,
    /// properties of SPA_TYPE_OBJECT_PropInfo
    pub const start = 0x0;
};

pub const Prop = enum(u32) {
    /// an unknown property
    unknown = 0x1,
    device = 0x101,
    device_name,
    device_fd,
    card,
    card_name,
    min_latency,
    max_latency,
    periods,
    period_size,
    period_event,
    live,
    rate,
    quality,
    bluetooth_audio_codec,
    bluetooth_offload_active,
    wave_type = 0x10001,
    frequency,
    /// a volume (Float), 0.0 silence, 1.0 no attenutation
    volume,
    /// mute (Bool)
    mute,
    pattern_type,
    dither_type,
    truncate,
    /// a volume array, one (linear) volume per channel (Array of Float). 0.0 is silence, 1.0 is without attenuation. This is the effective volume that is applied. It can result in a hardware volume and software volume (see softVolumes)
    channel_volumes,
    /// a volume base (Float)
    volume_base,
    /// a volume step (Float)
    volume_step,
    /// a channelmap array (Array (Id enum spa_audio_channel))
    channel_map,
    /// mute (Bool)
    monitor_mute,
    /// a volume array, one (linear) volume per channel (Array of Float)
    monitor_volumes,
    /// delay adjustment
    latency_offset_nsec,
    /// mute (Bool) applied in software
    soft_mute,
    /// a volume array, one (linear) volume per channel (Array of Float). 0.0 is silence, 1.0 is without attenuation. This is the volume applied in software, there might be a part applied in hardware.
    soft_volumes,
    /// enabled IEC958 (S/PDIF) codecs, (Array (Id enum spa_audio_iec958_codec)
    iec958_codecs,
    /// Samples to ramp the volume over
    volume_ramp_samples,
    /// Step or incremental Samples to ramp the volume over
    volume_ramp_step_samples,
    /// Time in millisec to ramp the volume over
    volume_ramp_time,
    /// Step or incremental Time in nano seconds to ramp the
    volume_ramp_step_time,
    /// the scale or graph to used to ramp the volume
    volume_ramp_scale,
    brightness = 0x20001,
    contrast,
    saturation,
    hue,
    gamma,
    exposure,
    gain,
    sharpness,
    /// simple control params (Struct( (String : key, Pod    : value)*))
    params = 0x80001,
    /// predefined properties for SPA_TYPE_OBJECT_Props
    pub const start = 0x0;
    /// device related properties
    pub const start_device = 0x100;
    /// audio related properties
    pub const start_audio = 0x10000;
    /// video related properties
    pub const start_video = 0x20000;
    /// other properties
    pub const start_other = 0x80000;
    pub const start_custom = 0x1000000;
};

pub const ParamTag = enum(u32) {
    /// direction, input/output (Id enum spa_direction)
    direction = 0x1,
    /// Struct( Int: n_items (String: key String: value)* )
    info,
    /// properties for SPA_TYPE_OBJECT_ParamTag
    pub const start = 0x0;
};

pub const VideoChromaSite = enum(u32) {
    /// unknown cositing
    unknown = 0x0,
    /// no cositing
    none = (1 << 0),
    /// chroma is horizontally cosited
    h_cosited = (1 << 1),
    /// chroma is vertically cosited
    v_cosited = (1 << 2),
    /// chroma samples are sited on alternate lines
    alt_line = (1 << 3),
    /// chroma samples cosited with luma samples
    cosited = (2 | 4),
    /// jpeg style cositing, also for mpeg1 and mjpeg
    jpeg = 0x9,
    /// mpeg2 style cositing
    mpeg2,
    dv = (6 | 8),
};

pub const VideoColorRange = enum(u32) {
    /// unknown range
    unknown = 0x0,
    /// [0..255] for 8 bit components
    u8_0_255,
    /// [16..235] for 8 bit components. Chroma has [16..240] range.
    u8_16_235,
};

pub const VideoColorMatrix = enum(u32) {
    /// unknown matrix
    unknown = 0x0,
    /// identity matrix
    rgb,
    /// FCC color matrix
    fcc,
    /// ITU BT.709 color matrix
    bt709,
    /// ITU BT.601 color matrix
    bt601,
    /// SMTPE  240M color matrix
    smpte240_m,
    /// ITU-R BT.2020 color matrix. since 1.6.
    bt2020,
};

pub const VideoTransferFunction = enum(u32) {
    /// unknown transfer function
    unknown = 0x0,
    /// linear RGB, gamma 1.0 curve
    gamma10,
    /// Gamma 1.8 curve
    gamma18,
    /// Gamma 2.0 curve
    gamma20,
    /// Gamma 2.2 curve
    gamma22,
    /// Gamma 2.2 curve with a linear segment in the lower range
    bt709,
    /// Gamma 2.2 curve with a linear segment in the lower range
    smpte240_m,
    /// Gamma 2.4 curve with a linear segment in the lower range
    srgb,
    /// Gamma 2.8 curve
    gamma28,
    /// Logarithmic transfer characteristic 100:1 range
    log100,
    /// Logarithmic transfer characteristic 316.22777:1 range
    log316,
    /// 1.6.
    bt2020_12,
    /// 1.8
    adobergb,
};

pub const VideoColorPrimaries = enum(u32) {
    /// unknown color primaries
    unknown = 0x0,
    /// BT709 primaries
    bt709,
    /// BT470M primaries
    bt470_m,
    /// BT470BG primaries
    bt470_bg,
    /// SMPTE170M primaries
    smpte170_m,
    /// SMPTE240M primaries
    smpte240_m,
    /// Generic film
    film,
    /// 1.6.
    bt2020,
    /// 1.8
    adobergb,
};

pub const VideoMultiviewMode = enum(u32) {
    /// A special value indicating no multiview information. Used in spa_video_info and other places to indicate that no specific multiview handling has been requested or provided. This value is never carried on caps.
    none = 0x1,
    /// All frames are monoscopic
    mono = 0x0,
    /// All frames represent a left-eye view
    left = 0x2,
    /// All frames represent a right-eye view
    right,
    /// Left and right eye views are provided in the left and right half of the frame respectively.
    side_by_side,
    /// Left and right eye views are provided in the left and right half of the frame, but have been sampled using quincunx method, with half-pixel offset between the 2 views.
    side_by_side_quincunx,
    /// Alternating vertical columns of pixels represent the left and right eye view respectively.
    column_interleaved,
    /// Alternating horizontal rows of pixels represent the left and right eye view respectively.
    row_interleaved,
    /// The top half of the frame contains the left eye, and the bottom half the right eye.
    top_bottom,
    /// Pixels are arranged with alternating pixels representing left and right eye views in a checkerboard fashion.
    checkerboard,
    /// Left and right eye views are provided in separate frames alternately.
    frame_by_frame = 0x20,
    /// Multipleindependent views are provided in separate frames in sequence. This method only applies to raw video buffers at the moment. Specific view identification is via metadata on raw video buffers.
    multiview_frame_by_frame,
    /// Multiple views are provided as separate  framebuffers attached to each described by the metadata
    separated,
};

pub const VideoMultiviewFlags = enum(u32) {
    /// No flags
    none = 0x0,
    /// For stereo streams, the normal arrangement of left and right views is reversed
    right_view_first = (1 << 0),
    /// The left view is vertically mirrored
    left_flipped = (1 << 1),
    /// The left view is horizontally mirrored
    left_flopped = (1 << 2),
    /// The right view is vertically mirrored
    right_flipped = (1 << 3),
    /// The right view is horizontally mirrored
    right_flopped = (1 << 4),
    /// For frame-packed multiview modes, indicates that the individual views have been encoded with half the true width or height and should be scaled back up for display. This flag is used for overriding input layout interpretation by adjusting pixel-aspect-ratio. For side-by-side, column interleaved or checkerboard packings, the pixel width will be doubled. For row interleaved and top-bottom encodings, pixel height will be doubled
    half_aspect = (1 << 14),
    /// The video stream contains both mono and multiview portions, signalled on each buffer by the absence or presence of a buffer flag.
    mixed_mono = (1 << 15),
};

pub const VideoFormat = enum(u32) {
    /// https://gstreamer.freedesktop.org/documentation/additional/design/mediatype-video-raw.html#formats
    unknown = 0x0,
    encoded,
    i420,
    yv12,
    yuy2,
    uyvy,
    ayuv,
    rgbx,
    bgrx,
    x_rgb,
    x_bgr,
    rgba,
    bgra,
    argb,
    abgr,
    rgb,
    bgr,
    y41_b,
    y42_b,
    yvyu,
    y444,
    v210,
    v216,
    nv12,
    nv21,
    gray8,
    gray16_be,
    gray16_le,
    v308,
    rgb16,
    bgr16,
    rgb15,
    bgr15,
    uyvp,
    a420,
    rgb8_p,
    yuv9,
    yvu9,
    iyu1,
    argb64,
    ayuv64,
    r210,
    i420_10_be,
    i420_10_le,
    i422_10_be,
    i422_10_le,
    y444_10_be,
    y444_10_le,
    gbr,
    gbr_10_be,
    gbr_10_le,
    nv16,
    nv24,
    nv12_64_z32,
    a420_10_be,
    a420_10_le,
    a422_10_be,
    a422_10_le,
    a444_10_be,
    a444_10_le,
    nv61,
    p010_10_be,
    p010_10_le,
    iyu2,
    vyuy,
    gbra,
    gbra_10_be,
    gbra_10_le,
    gbr_12_be,
    gbr_12_le,
    gbra_12_be,
    gbra_12_le,
    i420_12_be,
    i420_12_le,
    i422_12_be,
    i422_12_le,
    y444_12_be,
    y444_12_le,
    rgba_f16,
    rgba_f32,
    /// 32-bit x:R:G:B 2:10:10:10 little endian
    x_rgb_210_le,
    /// 32-bit x:B:G:R 2:10:10:10 little endian
    x_bgr_210_le,
    /// 32-bit R:G:B:x 10:10:10:2 little endian
    rgbx_102_le,
    /// 32-bit B:G:R:x 10:10:10:2 little endian
    bgrx_102_le,
    /// 32-bit A:R:G:B 2:10:10:10 little endian
    argb_210_le,
    /// 32-bit A:B:G:R 2:10:10:10 little endian
    abgr_210_le,
    /// 32-bit R:G:B:A 10:10:10:2 little endian
    rgba_102_le,
    /// 32-bit B:G:R:A 10:10:10:2 little endian
    bgra_102_le,
    dsp_f32,
};

pub const VideoFlags = enum(u32) {
    /// no flags
    none = 0x0,
    /// a variable fps is selected, fps_n and fps_d denote the maximum fps of the video
    variable_fps = (1 << 0),
    /// Each color has been scaled by the alpha value.
    premultiplied_alpha = (1 << 1),
    /// use the format modifier
    modifier = (1 << 2),
    /// format modifier was not fixated yet
    modifier_fixation_required = (1 << 3),
};

pub const VideoInterlaceMode = enum(u32) {
    /// all frames are progressive
    progressive = 0x0,
    /// 2 fields are interleaved in one video frame. Extra buffer flags describe the field order.
    interleaved,
    /// frames contains both interlaced and progressive video, the buffer flags describe the frame and fields.
    mixed,
    /// 2 fields are stored in one buffer, use the frame ID to get access to the required field. For multiview (the 'views' property > 1) the fields of view N can be found at frame ID (N * 2) and (N * 2) + 1. Each field has only half the amount of lines as noted in the height property. This mode requires multiple spa_data to describe the fields.
    fields,
};

pub const H264StreamFormat = enum(u32) {
    unknown = 0x0,
    avc,
    avc3,
    bytestream,
};

pub const H264Alignment = enum(u32) {
    unknown = 0x0,
    au,
    nal,
};

pub const BluetoothAudioCodec = enum(u32) {
    sbc = 0x1,
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
    lc3_plus_hr,
    opus_05,
    opus_05_51,
    opus_05_71,
    opus_05_duplex,
    opus_05_pro,
    opus_g,
    cvsd = 0x100,
    msbc,
    lc3_swb,
    lc3 = 0x200,
    g722 = 0x300,
    pub const start = 0x0;
};

pub const AudioFormat = enum(u32) {
    unknown = 0x0,
    encoded,
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
    u8_p = 0x201,
    s16_p,
    s24_32_p,
    s32_p,
    s24_p,
    f32_p,
    f64_p,
    s8_p,
    dsp_s32 = 0x401,
    dsp_f32,
    dsp_f64,
    s16,
    u16,
    s24_32,
    u24_32,
    s32,
    u32,
    s24,
    u24,
    s20,
    u20,
    s18,
    u18,
    f32,
    f64,
    s16_oe,
    u16_oe,
    s24_32_oe,
    u24_32_oe,
    s32_oe,
    u32_oe,
    s24_oe,
    u24_oe,
    s20_oe,
    u20_oe,
    s18_oe,
    u18_oe,
    f32_oe,
    f64_oe,
    pub const start_interleaved = 0x100;
    pub const start_planar = 0x200;
    pub const start_other = 0x400;
};

pub const AudioChannel = enum(u32) {
    /// unspecified
    unknown = 0x0,
    /// N/A, silent
    na,
    /// mono stream
    mono,
    /// front left
    fl,
    /// front right
    fr,
    /// front center
    fc,
    /// LFE
    lfe,
    /// side left
    sl,
    /// side right
    sr,
    /// front left center
    flc,
    /// front right center
    frc,
    /// rear center
    rc,
    /// rear left
    rl,
    /// rear right
    rr,
    /// top center
    tc,
    /// top front left
    tfl,
    /// top front center
    tfc,
    /// top front right
    tfr,
    /// top rear left
    trl,
    /// top rear center
    trc,
    /// top rear right
    trr,
    /// rear left center
    rlc,
    /// rear right center
    rrc,
    /// front left wide
    flw,
    /// front right wide
    frw,
    /// LFE 2
    lfe2,
    /// front left high
    flh,
    /// front center high
    fch,
    /// front right high
    frh,
    /// top front left center
    tflc,
    /// top front right center
    tfrc,
    /// top side left
    tsl,
    /// top side right
    tsr,
    /// left LFE
    llfe,
    /// right LFE
    rlfe,
    /// bottom center
    bc,
    /// bottom left center
    blc,
    /// bottom right center
    brc,
    aux0 = 0x1001,
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
    /// aux channels
    pub const start_aux = 0x1000;
    /// aux channels
    pub const last_aux = 0x1fff;
    pub const start_custom = 0x10000;
};

pub const AudioVolumeRampScale = enum(u32) {
    invalid = 0x0,
    linear,
    cubic,
};

pub const AudioIec958Codec = enum(u32) {
    unknown = 0x0,
    pcm,
    dts,
    ac3,
    /// MPEG-1 or MPEG-2 (Part 3, not AAC)
    mpeg,
    /// MPEG-2 AAC
    mpeg2_aac,
    eac3,
    /// Dolby TrueHD
    truehd,
    /// DTS-HD Master Audio
    dtshd,
};

pub const AudioMp3ChannelMode = enum(u32) {
    unknown = 0x0,
    mono,
    stereo,
    jointstereo,
    dual,
};

pub const AudioAacStreamFormat = enum(u32) {
    unknown = 0x0,
    raw,
    mp2_adts,
    mp4_adts,
    mp4_loas,
    mp4_latm,
    adif,
    mp4_ff,
    custom = 0x10000,
};

pub const AudioWmaProfile = enum(u32) {
    unknown = 0x0,
    wma7,
    wma8,
    wma9,
    wma10,
    wma9_pro,
    wma9_lossless,
    wma10_lossless,
    custom = 0x10000,
};

pub const AudioAmrBandMode = enum(u32) {
    unknown = 0x0,
    nb,
    wb,
};

pub const MetaType = enum(u32) {
    invalid = 0x0,
    /// struct spa_meta_header
    header,
    /// struct spa_meta_region with cropping data
    video_crop,
    /// array of struct spa_meta_region with damage, where an invalid entry or end-of-array marks the end.
    video_damage,
    /// struct spa_meta_bitmap
    bitmap,
    /// struct spa_meta_cursor
    cursor,
    /// metadata contains a spa_meta_control associated with the data
    control,
    /// don't write to buffer when count > 0
    busy,
    /// struct spa_meta_transform
    video_transform,
    /// struct spa_meta_sync_timeline
    sync_timeline,
    /// not part of ABI/API
    pub const last = 0xa;
};

pub const MetaVideoTransformValue = enum(u32) {
    /// no transform
    none = 0x0,
    /// 90 degree counter-clockwise
    ccw_90,
    /// 180 degree counter-clockwise
    ccw_180,
    /// 270 degree counter-clockwise
    ccw_270,
    /// 180 degree flipped around the vertical axis. Equivalent to a reflexion through the vertical line splitting the buffer in two equal sized parts
    flipped,
    /// flip then rotate around 90 degree counter-clockwise
    flipped_ccw_90,
    /// flip then rotate around 180 degree counter-clockwise
    flipped_ccw_180,
    /// flip then rotate around 270 degree counter-clockwise
    flipped_ccw_270,
};

pub const DataType = enum(u32) {
    invalid = 0x0,
    /// pointer to memory, the data field in struct spa_data is set.
    mem_ptr,
    /// memfd, mmap to get to memory.
    mem_fd,
    /// fd to dmabuf memory. This might not be readily mappable (unless the MAPPABLE flag is set) and should normally be handled with DMABUF apis.
    dma_buf,
    /// memory is identified with an id. The actual memory can be obtained in some other way and can be identified with this id.
    mem_id,
    /// a syncobj, usually requires a spa_meta_sync_timeline metadata with timeline points.
    sync_obj,
    /// not part of ABI
    pub const last = 0x6;
};

pub const ControlType = enum(u32) {
    /// Different Control types
    invalid = 0x0,
    /// SPA_TYPE_OBJECT_Props
    properties,
    /// spa_pod_bytes with raw midi data (deprecated, use SPA_CONTROL_UMP)
    midi,
    /// spa_pod_bytes with an OSC packet
    osc,
    /// spa_pod_bytes with raw UMP (universal MIDI packet) data. The UMP 32 bit words are stored in native endian format.
    ump,
    /// not part of ABI
    pub const last = 0x5;
};

pub const NodeCommand = enum(u32) {
    /// suspend a node, this removes all configured formats and closes any devices
    @"suspend" = 0x0,
    /// pause a node. this makes it stop emitting scheduling events
    pause,
    /// start a node, this makes it start emitting scheduling events
    start,
    enable,
    disable,
    flush,
    drain,
    marker,
    /// begin a set of parameter enumerations or configuration that require the device to remain opened, like query formats and then set a format
    param_begin,
    /// end a transaction
    param_end,
    /// Sent to a driver when some other node emitted the RequestProcess event.
    request_process,
};

pub const NodeEvent = enum(u32) {
    @"error" = 0x0,
    buffering,
    request_refresh,
    request_process,
};

pub const EventNode = enum(u32) {
    pub const start = 0x0;
};

pub const IoType = enum(u32) {
    /// Different IO area types
    invalid = 0x0,
    /// area to exchange buffers, struct spa_io_buffers
    buffers,
    /// expected byte range, struct spa_io_range (currently not used in PipeWire)
    range,
    /// area to update clock information, struct spa_io_clock
    clock,
    /// spa_param_latency
    latency,
    /// area for control messages, struct spa_io_sequence
    control,
    /// area for notify messages, struct spa_io_sequence
    notify,
    /// position information in the graph, struct spa_io_position
    position,
    /// rate matching between nodes, struct spa_io_rate_match
    rate_match,
    /// memory pointer, struct spa_io_memory (currently not used in PipeWire)
    memory,
    /// async area to exchange buffers, struct spa_io_async_buffers
    async_buffers,
};

pub const IoPositionState = enum(u32) {
    stopped = 0x0,
    starting,
    running,
};

pub const DeviceEvent = enum(u32) {
    config = 0x0,
};

pub const EventDevice = enum(u32) {
    object = 0x1,
    props,
    pub const start = 0x0;
};
