# PortAudio

This is [PortAudio](https://www.portaudio.com) packaged for Zig.

## Build options

Use `-Dhost-api=` to choose a specific audio backend for your target OS. By default, the following are used:

- Core Audio (macOS)
- ALSA (Linux)
- WASAPI (Windows)

## Limitations

- The ASIO backend is not currently supported. See [this PortAudio tutorial](https://www.portaudio.com/docs/v19-doxydocs/compile_windows_asio_msvc.html) for information on why this is not straightforward.
- Test programs are not compiled.
