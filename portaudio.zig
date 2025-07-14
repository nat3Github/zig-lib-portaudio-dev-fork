const std = @import("std");
const assert = std.debug.assert;
const expect = std.debug.expect;
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
pub const c = @import("portaudio_c");

pub const PortAudio = @This();
fn errify_print(err: c.PaError) !void {
    errify(err) catch |e| {
        std.log.err("error: {}", .{e});
        return e;
    };
}

fn errify(err: c.PaError) !void {
    if (err < 0) {
        switch (err) {
            c.paNoError => {},
            c.paNotInitialized => return error.PortAudioNotInitialized,
            c.paUnanticipatedHostError => return error.PortAudioUnanticipatedHostError,
            c.paInvalidChannelCount => return error.PortAudioInvalidChannelCount,
            c.paInvalidSampleRate => return error.PortAudioInvalidSampleRate,
            c.paInvalidDevice => return error.PortAudioInvalidDevice,
            c.paInvalidFlag => return error.PortAudioInvalidFlag,
            c.paSampleFormatNotSupported => return error.PortAudioSampleFormatNotSupported,
            c.paBadIODeviceCombination => return error.PortAudioBadIODeviceCombination,
            c.paInsufficientMemory => return error.PortAudioInsufficientMemory,
            c.paBufferTooBig => return error.PortAudioBufferTooBig,
            c.paBufferTooSmall => return error.PortAudioBufferTooSmall,
            c.paNullCallback => return error.PortAudioNullCallback,
            c.paBadStreamPtr => return error.PortAudioBadStreamPtr,
            c.paTimedOut => return error.PortAudioTimedOut,
            c.paInternalError => return error.PortAudioInternalError,
            c.paDeviceUnavailable => return error.PortAudioDeviceUnavailable,
            c.paIncompatibleHostApiSpecificStreamInfo => return error.PortAudioIncompatibleHostApiSpecificStreamInfo,
            c.paStreamIsStopped => return error.PortAudioStreamIsStopped,
            c.paStreamIsNotStopped => return error.PortAudioStreamIsNotStopped,
            c.paInputOverflowed => return error.PortAudioInputOverflowed,
            c.paOutputUnderflowed => return error.PortAudioOutputUnderflowed,
            c.paHostApiNotFound => return error.PortAudioHostApiNotFound,
            c.paInvalidHostApi => return error.PortAudioInvalidHostApi,
            c.paCanNotReadFromACallbackStream => return error.PortAudioCanNotReadFromACallbackStream,
            c.paCanNotWriteToACallbackStream => return error.PortAudioCanNotWriteToACallbackStream,
            c.paCanNotReadFromAnOutputOnlyStream => return error.PortAudioCanNotReadFromAnOutputOnlyStream,
            c.paCanNotWriteToAnInputOnlyStream => return error.PortAudioCanNotWriteToAnInputOnlyStream,
            c.paIncompatibleStreamHostApi => return error.PortAudioIncompatibleStreamHostApi,
            c.paBadBufferPtr => return error.PortAudioBadBufferPtr,
            c.paCanNotInitializeRecursively => return error.PortAudioCanNotInitializeRecursively,
            else => panic("error not recognized", .{}),
        }
    }
}

pub fn init() !PortAudio {
    try errify(c.Pa_Initialize());
    return PortAudio{};
}
pub fn deinit(_: *PortAudio) void {
    errify_print(c.Pa_Terminate()) catch {};
}
pub fn get_host_api_count(_: *PortAudio) usize {
    const res = c.Pa_GetHostApiCount();
    errify_print(res) catch return 0;
    return @intCast(res);
}
pub fn get_host_api_info(self: *PortAudio, host_idx: usize) *const c.struct_PaHostApiInfo {
    assert(host_idx < self.get_host_api_count());
    const res = c.Pa_GetHostApiInfo(@intCast(host_idx));
    return res.?;
}

pub fn get_device_count(_: *PortAudio) usize {
    const res = c.Pa_GetDeviceCount();
    errify_print(res) catch return 0;
    return @intCast(res);
}

pub fn get_device_info(self: *PortAudio, device_idx: usize) *const c.struct_PaDeviceInfo {
    assert(device_idx < self.get_device_count());
    const ret: ?*const c.struct_PaDeviceInfo = c.Pa_GetDeviceInfo(@intCast(device_idx)).?;
    if (ret) |r| return r else unreachable;
}
pub fn index_of_default_input_device(_: *PortAudio) !usize {
    const res = c.Pa_GetDefaultInputDevice();
    try errify_print(res);
    return @intCast(res);
}
pub fn index_of_default_output_device(_: *PortAudio) !usize {
    const res = c.Pa_GetDefaultOutputDevice();
    try errify_print(res);
    return @intCast(res);
}

pub const Stream = struct {
    const Config = struct {
        input_params: c.PaStreamParameters,
        output_params: c.PaStreamParameters,
        srate: f64,
        frames: u64,
        flags: c.PaStreamFlags,
    };
    raw: *c.PaStream = undefined,
    pub fn init(
        cfg: Stream.Config,
        callback: c.PaStreamCallback,
        user_data: ?*anyopaque,
    ) !Stream {
        var ptr: ?*c.PaStream = null;
        const err = c.Pa_OpenStream(
            &ptr,
            &cfg.input_params,
            &cfg.output_params,
            cfg.srate,
            @intCast(cfg.frames),
            cfg.flags,
            callback,
            user_data,
        );
        try errify_print(err);
        return Stream{
            .raw = ptr.?,
        };
    }
    pub fn start(self: *Stream) !void {
        const err = c.Pa_StartStream(self.raw);
        try errify_print(err);
    }
    pub fn stop(self: *Stream) !void {
        const err = c.Pa_StopStream(self.raw);
        try errify_print(err);
    }
    pub fn abort(self: *Stream) !void {
        const err = c.Pa_AbortStream(self.raw);
        try errify_print(err);
    }
    pub fn close(self: *Stream) !void {
        const err = c.Pa_CloseStream(self.raw);
        try errify_print(err);
    }
    pub fn is_active(self: *Stream) !bool {
        const err = c.Pa_IsStreamActive(self.raw);
        try errify_print(err);
        return err == 1;
    }
    pub fn is_stopped(self: *Stream) !bool {
        const err = c.Pa_IsStreamStopped(self.raw);
        try errify_print(err);
        return err == 1;
    }
    pub fn get_info(self: *Stream) !*const c.struct_PaStreamInfo {
        const ret: ?*const c.struct_PaStreamInfo = c.Pa_GetStreamInfo(self.raw);
        if (ret) |r| return r else return error.PortAudioNullPointer;
    }
    pub fn get_time(self: *Stream) f64 {
        return c.Pa_GetStreamTime(self.raw);
    }
    pub fn get_cpu_load(self: *Stream) f64 {
        return c.Pa_GetStreamCpuLoad(self.raw);
    }
};
fn get_sample_format_type(self: c.PaSampleFormat) type {
    return switch (self) {
        c.paInt8 => i8,
        c.paInt16 => i16,
        c.paInt24 => i24,
        c.paInt32 => i32,
        c.paFloat32 => f32,
    };
}

pub const TStreamF32 = struct {
    const UserData = struct {
        t: *anyopaque,
        t_callback: *const fn (*anyopaque, []const f32, []f32, usize) void,
        in_channels: usize,
        out_channels: usize,
    };
    stream: Stream,
    user_data: UserData,
    alloc: Allocator,

    fn callback(
        in_ptr: ?*const anyopaque,
        out_ptr: ?*anyopaque,
        cframes: c_ulong,
        _: [*c]const c.PaStreamCallbackTimeInfo,
        _: c.PaStreamCallbackFlags,
        user_data: ?*anyopaque,
    ) callconv(.c) c_int {
        if (in_ptr == null or out_ptr == null) return c.paAbort;
        const ud = @as(*UserData, @alignCast(@ptrCast(user_data)));
        const frames: usize = @intCast(cframes);

        const in_p: [*]f32 = @alignCast(@ptrCast(out_ptr));
        var in_slc: []f32 = undefined;
        in_slc.len = frames * ud.in_channels;
        in_slc.ptr = in_p;

        const out_p: [*]f32 = @alignCast(@ptrCast(out_ptr));
        var out_slice: []f32 = undefined;
        out_slice.len = frames * ud.out_channels;
        out_slice.ptr = out_p;

        ud.t_callback(ud.t, in_slc, out_slice, frames);
        return c.paContinue;
    }
    pub fn init(
        self: *@This(),
        t: *anyopaque,
        /// *T, input interleaved, output interleaved, frames
        t_callback: *const fn (*anyopaque, []const f32, []f32, usize) void,
        flags: ?c.PaStreamFlags,
        in_device_idx: usize,
        in_channels: usize,
        out_device_idx: usize,
        out_channels: usize,
        srate: f64,
        frames: usize,
    ) !void {
        self.user_data = UserData{
            .in_channels = in_channels,
            .out_channels = out_channels,
            .t = t,
            .t_callback = t_callback,
        };
        const config: Stream.Config = .{
            .flags = flags orelse c.paNoFlag,
            .frames = frames,
            .input_params = .{
                .channelCount = @intCast(in_channels),
                .sampleFormat = c.paFloat32,
                .suggestedLatency = 0,
                .device = @intCast(in_device_idx),
            },
            .output_params = .{
                .channelCount = @intCast(out_channels),
                .sampleFormat = c.paFloat32,
                .suggestedLatency = 0,
                .device = @intCast(out_device_idx),
            },
            .srate = srate,
        };
        self.stream = try Stream.init(
            config,
            callback,
            &self.user_data,
        );
    }
};

fn print_device_info(
    pa: *PortAudio,
    dv_idx: usize,
) void {
    const info = pa.get_device_info(dv_idx);
    const fmt =
        \\ device {s}, idx: {} info
        \\ def input latency, high: {} low: {}
        \\ def output latency, high: {} low: {}
        \\ def srate: {}
        \\ in channels: {} out channels {}
        \\ host api: {s}
        \\
    ;
    const host_api = pa.get_host_api_info(@intCast(info.hostApi));

    std.log.warn(fmt, .{
        info.name,
        dv_idx,
        info.defaultHighInputLatency,
        info.defaultLowInputLatency,
        info.defaultHighOutputLatency,
        info.defaultLowOutputLatency,
        info.defaultSampleRate,
        info.maxInputChannels,
        info.maxOutputChannels,
        host_api.name,
    });
}
test "show devices" {
    var pa = try PortAudio.init();
    defer pa.deinit();
    const default_device_idx = try pa.index_of_default_output_device();
    const default_input_idx = try pa.index_of_default_input_device();
    print_device_info(&pa, @intCast(default_device_idx));
    print_device_info(&pa, @intCast(default_input_idx));
}

pub const CallbackTimeInfo = c.PaStreamCallbackTimeInfo;
pub const CallbackFlags = c.PaStreamCallbackFlags;
const Atomic = std.atomic.Value;

const Sine = struct {
    const fade_out: u64 = 48000 * 2;
    sinex: u64 = 0,
    stop: *Atomic(bool),
    stop_counter: u64 = fade_out,
    stop_event: *std.Thread.ResetEvent,
    fn init(stop: *Atomic(bool), stop_ev: *std.Thread.ResetEvent) !Sine {
        return Sine{
            .stop = stop,
            .stop_event = stop_ev,
        };
    }
    pub fn generateSineWave(frequency: f64, frame: usize, sampleRate: usize) f64 {
        const time: f64 = @as(f64, @floatFromInt(frame)) / @as(f64, @floatFromInt(sampleRate));
        return std.math.sin(2.0 * std.math.pi * frequency * time);
    }
    fn callback(xself: *anyopaque, _: []const f32, out: []f32, frames: usize) void {
        const self: *Sine = @alignCast(@ptrCast(xself));
        var vol: f32 = 1.0 / (@as(f32, @floatFromInt(self.sinex + 1)) / 1000.0);
        vol = 1.0;
        if (self.stop.load(.unordered)) {
            self.stop_counter = std.math.sub(u64, self.stop_counter, @intCast(frames)) catch 0;
            if (self.stop_counter == 0) {
                self.stop_event.set();
            }
            vol *= @as(f32, @floatFromInt(self.stop_counter)) / @as(f32, @floatFromInt(fade_out));
        }
        const channels = out.len / frames;
        for (0..frames) |frame| {
            const f: f32 = @floatCast(generateSineWave(300, frame + self.sinex, 48000));
            for (0..channels) |chan| {
                const iindex = channels * frame + chan;
                out[iindex] = f * vol;
            }
        }
        self.sinex += frames;
    }
};

test "play sine" {
    const alloc = std.testing.allocator;
    var pa = try PortAudio.init();
    defer pa.deinit();
    const def_out_device_idx = try pa.index_of_default_output_device();
    const def_out_info = pa.get_device_info(def_out_device_idx);

    const def_in_device_idx = try pa.index_of_default_input_device();
    const def_in_info = pa.get_device_info(def_in_device_idx);

    const tcb = try alloc.create(Sine);

    var stop = Atomic(bool).init(false);
    var stop_ev = std.Thread.ResetEvent{};
    tcb.* = try Sine.init(&stop, &stop_ev);
    defer alloc.destroy(tcb);
    const in_channels: usize = @intCast(def_in_info.maxInputChannels);
    const out_channels: usize = @intCast(def_out_info.maxOutputChannels);

    const frames = 2048;
    var sw = try TStreamF32.init(
        alloc,
        tcb,
        Sine.callback,
        null,
        def_in_device_idx,
        in_channels,
        def_out_device_idx,
        out_channels,
        48000,
        frames,
    );
    defer sw.deinit();
    try sw.stream.start();
    std.Thread.sleep(2e9);
    stop.store(true, .unordered);
    stop_ev.wait();
    try sw.stream.stop();
}
test "test all refs" {
    std.testing.refAllDecls(@This());
    std.log.warn("hello world", .{});
}
