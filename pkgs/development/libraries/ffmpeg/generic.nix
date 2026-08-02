{
  lib,
  config,
  stdenv,
  buildPackages,
  removeReferencesTo,
  addDriverRunpath,
  pkg-config,
  perl,
  texinfo,
  nasm,

  # You can fetch any upstream version using this derivation by specifying version and hash
  # NOTICE: Always use this argument to override the version. Do not use overrideAttrs.
  version, # ffmpeg ABI version. Also declare this if you're overriding the source.
  hash ? "", # hash of the upstream source for the given ABI version
  source ? fetchgit {
    url = "https://git.ffmpeg.org/ffmpeg.git";
    rev = "n${version}";
    inherit hash;
  },

  ffmpegVariant ? "small", # Decides which dependencies are enabled by default

  # Build with headless deps; excludes dependencies that are only necessary for
  # GUI applications. To be used for purposes that don't generally need such
  # components and i.e. only depend on libav
  withHeadlessDeps ? ffmpegVariant == "headless" || withSmallDeps,

  # Dependencies a user might customarily expect from a regular ffmpeg build.
  # /All/ packages that depend on ffmpeg and some of its feaures should depend
  # on the small variant. Small means the minimal set of features that satisfies
  # all dependants in Nixpkgs
  withSmallDeps ? ffmpegVariant == "small" || withFullDeps,

  # Everything enabled; only guarded behind platform exclusivity or brokenness.
  # If you need to depend on ffmpeg-full because ffmpeg is missing some feature
  # your package needs, you should enable that feature in regular ffmpeg
  # instead.
  withFullDeps ? ffmpegVariant == "full",

  fetchgit,
  fetchpatch2,

  # Feature flags
  withAlsa ? withHeadlessDeps && stdenv.hostPlatform.isLinux, # Alsa in/output supporT
  withAmf ? withHeadlessDeps && lib.meta.availableOn stdenv.hostPlatform amf, # AMD Media Framework video encoding
  withAom ? withHeadlessDeps, # AV1 reference encoder
  withAribb24 ? withFullDeps, # ARIB text and caption decoding
  withAribcaption ? withFullDeps && lib.versionAtLeast version "6.1", # ARIB STD-B24 Caption Decoder/Renderer
  withAss ? withHeadlessDeps && stdenv.hostPlatform == stdenv.buildPlatform, # (Advanced) SubStation Alpha subtitle rendering
  withAvisynth ? withFullDeps, # AviSynth script files reading
  withBluray ? withHeadlessDeps, # BluRay reading
  withBs2b ? withFullDeps, # bs2b DSP library
  withBzlib ? withHeadlessDeps,
  withCaca ? withFullDeps, # Textual display (ASCII art)
  withCdio ? withFullDeps && withGPL, # Audio CD grabbing
  withCelt ? withFullDeps, # CELT decoder
  withChromaprint ? withFullDeps, # Audio fingerprinting
  withCodec2 ? withFullDeps, # codec2 en/decoding
  withCuda ? withFullDeps && withNvcodec,
  withCudaLLVM ?
    withHeadlessDeps
    # Cuda isn’t supported on Darwin
    && !stdenv.hostPlatform.isDarwin
    # Clang for our ppc64 targets needs cc-wrapper to work
    && !(stdenv.buildPlatform.isPower64 && stdenv.buildPlatform.isBigEndian),
  withCudaNVCC ? withFullDeps && withUnfree && config.cudaSupport,
  withCuvid ? withHeadlessDeps && withNvcodec,
  withDav1d ? withHeadlessDeps, # AV1 decoder (focused on speed and correctness)
  withDavs2 ? withFullDeps && withGPL, # AVS2 decoder
  withDc1394 ? withFullDeps && !stdenv.hostPlatform.isDarwin, # IIDC-1394 grabbing (ieee 1394)
  withDrm ? withHeadlessDeps && (with stdenv; isLinux || isFreeBSD), # libdrm support
  withDvdnav ? withFullDeps && withGPL && lib.versionAtLeast version "7", # needed for DVD demuxing
  withDvdread ? withFullDeps && withGPL && lib.versionAtLeast version "7", # needed for DVD demuxing
  withFdkAac ? withFullDeps && (!withGPL || withUnfree), # Fraunhofer FDK AAC de/encoder
  withNvcodec ?
    withHeadlessDeps
    && (
      with stdenv;
      !isDarwin
      && !isAarch32
      && !hostPlatform.isLoongArch64
      && !hostPlatform.isRiscV
      && !(hostPlatform.isPower && hostPlatform.isBigEndian)
      && hostPlatform == buildPlatform
    ), # dynamically linked Nvidia code
  withFlite ? withFullDeps, # Voice Synthesis
  withFontconfig ? withHeadlessDeps, # Needed for drawtext filter
  withFreetype ? withHeadlessDeps, # Needed for drawtext filter
  withFrei0r ? withFullDeps && withGPL, # frei0r video filtering
  withFribidi ? withHeadlessDeps, # Needed for drawtext filter
  withGme ? withFullDeps, # Game Music Emulator
  withGmp ? withHeadlessDeps && withVersion3, # rtmp(t)e support
  withGnutls ? withHeadlessDeps,
  withGsm ? withFullDeps, # GSM de/encoder
  withHarfbuzz ? withHeadlessDeps && lib.versionAtLeast version "6.1", # Needed for drawtext filter
  withIconv ? withHeadlessDeps,
  withIlbc ? withFullDeps, # iLBC de/encoding
  withJack ? withFullDeps && !stdenv.hostPlatform.isDarwin, # Jack audio
  withJxl ? withFullDeps && lib.versionAtLeast version "5", # JPEG XL de/encoding
  withKvazaar ? withFullDeps, # HEVC encoding
  withLadspa ? withFullDeps, # LADSPA audio filtering
  withLc3 ? withFullDeps && lib.versionAtLeast version "7.1", # LC3 de/encoding
  withLcevcdec ? withFullDeps && lib.versionAtLeast version "7.1", # LCEVC decoding
  withLcms2 ? withFullDeps, # ICC profile support via lcms2
  withLzma ? withHeadlessDeps, # xz-utils
  withMetal ? false, # Unfree and requires manual downloading of files
  withMfx ? false, # Hardware acceleration via intel-media-sdk/libmfx
  withModplug ? withFullDeps && !stdenv.hostPlatform.isDarwin, # ModPlug support
  withMp3lame ? withHeadlessDeps, # LAME MP3 encoder
  withMysofa ? withFullDeps, # HRTF support via SOFAlizer
  withNpp ? withFullDeps && withUnfree && config.cudaSupport, # Nvidia Performance Primitives-based code
  withNvdec ? withHeadlessDeps && withNvcodec,
  withNvenc ? withHeadlessDeps && withNvcodec,
  withOpenal ? withFullDeps, # OpenAL 1.1 capture support
  withOpenapv ? withHeadlessDeps && lib.versionAtLeast version "8.0", # APV encoding support
  withOpencl ? withHeadlessDeps,
  withOpencoreAmrnb ? withFullDeps && withVersion3, # AMR-NB de/encoder
  withOpencoreAmrwb ? withFullDeps && withVersion3, # AMR-WB decoder
  withOpengl ? withFullDeps && !stdenv.hostPlatform.isDarwin, # OpenGL rendering
  withOpenh264 ? withFullDeps, # H.264/AVC encoder
  withOpenjpeg ? withHeadlessDeps, # JPEG 2000 de/encoder
  withOpenmpt ? withHeadlessDeps, # Tracked music files decoder
  withOpus ? withHeadlessDeps, # Opus de/encoder
  withPlacebo ? withFullDeps && !stdenv.hostPlatform.isDarwin, # libplacebo video processing library
  withPulse ? withSmallDeps && stdenv.hostPlatform.isLinux, # Pulseaudio input support
  withQrencode ? withFullDeps && lib.versionAtLeast version "7", # QR encode generation
  withQuirc ? withFullDeps && lib.versionAtLeast version "7", # QR decoding
  withRav1e ? withFullDeps, # AV1 encoder (focused on speed and safety)
  withRist ? withHeadlessDeps, # Reliable Internet Stream Transport (RIST) protocol
  withRtmp ? false, # RTMP[E] support via librtmp
  withRubberband ? withFullDeps && withGPL && !stdenv.hostPlatform.isFreeBSD, # Rubberband filter
  withSamba ? withFullDeps && !stdenv.hostPlatform.isDarwin && withGPLv3, # Samba protocol
  withSdl2 ? withSmallDeps,
  withShaderc ? withFullDeps && !stdenv.hostPlatform.isDarwin && lib.versionAtLeast version "5.0",
  withShine ? withFullDeps, # Fixed-point MP3 encoding
  withSnappy ? withFullDeps, # Snappy compression, needed for hap encoding
  withSoxr ? withHeadlessDeps, # Resampling via soxr
  withSpeex ? withHeadlessDeps, # Speex de/encoder
  withSrt ? withHeadlessDeps, # Secure Reliable Transport (SRT) protocol
  withSsh ? withHeadlessDeps, # SFTP protocol
  withSvg ? withFullDeps, # SVG protocol
  withSvtav1 ? withHeadlessDeps && !stdenv.hostPlatform.isMinGW, # AV1 encoder/decoder (focused on speed and correctness)
  withTensorflow ? false, # Tensorflow dnn backend support (Increases closure size by ~390 MiB)
  withTheora ? withHeadlessDeps, # Theora encoder
  withTwolame ? withFullDeps, # MP2 encoding
  withUavs3d ? withFullDeps, # AVS3 decoder
  withV4l2 ? withHeadlessDeps && stdenv.hostPlatform.isLinux, # Video 4 Linux support
  withV4l2M2m ? withV4l2,
  withVaapi ? withHeadlessDeps && (with stdenv; isLinux || isFreeBSD), # Vaapi hardware acceleration
  withVdpau ? withSmallDeps && (with stdenv; isLinux || isFreeBSD), # Vdpau hardware acceleration
  withVidStab ? withHeadlessDeps && withGPL, # Video stabilization
  withVmaf ? withFullDeps && lib.versionAtLeast version "5", # Netflix's VMAF (Video Multi-Method Assessment Fusion)
  withVoAmrwbenc ? withFullDeps && withVersion3, # AMR-WB encoder
  withVorbis ? withHeadlessDeps, # Vorbis de/encoding, native encoder exists
  withVpl ? withFullDeps && stdenv.hostPlatform.isLinux, # Hardware acceleration via intel libvpl
  withVpx ? withHeadlessDeps && stdenv.buildPlatform == stdenv.hostPlatform, # VP8 & VP9 de/encoding
  withVulkan ? withHeadlessDeps && !stdenv.hostPlatform.isDarwin,
  withVvenc ? withFullDeps && lib.versionAtLeast version "7.1", # H.266/VVC encoding
  withWebp ? withHeadlessDeps, # WebP encoder
  withWhisper ? withFullDeps && lib.versionAtLeast version "8.0", # Whisper speech recognition
  withX264 ? withHeadlessDeps && withGPL, # H.264/AVC encoder
  withX265 ? withHeadlessDeps && withGPL, # H.265/HEVC encoder
  withXavs ? withFullDeps && withGPL, # AVS encoder
  withXavs2 ? withFullDeps && withGPL, # AVS2 encoder
  withXcb ? withXcbShm || withXcbxfixes || withXcbShape, # X11 grabbing using XCB
  withXcbShape ? withFullDeps, # X11 grabbing shape rendering
  withXcbShm ? withFullDeps, # X11 grabbing shm communication
  withXcbxfixes ? withFullDeps, # X11 grabbing mouse rendering
  withXevd ? withFullDeps && lib.versionAtLeast version "7.1" && !xevd.meta.broken, # MPEG-5 EVC decoding
  withXeve ? withFullDeps && lib.versionAtLeast version "7.1" && !xeve.meta.broken, # MPEG-5 EVC encoding
  withXlib ? withFullDeps, # Xlib support
  withXml2 ? withHeadlessDeps, # libxml2 support, for IMF and DASH demuxers
  withXvid ? withHeadlessDeps && withGPL, # Xvid encoder, native encoder exists
  withZimg ? withHeadlessDeps,
  withZlib ? withHeadlessDeps,
  withZmq ? withFullDeps, # Message passing
  withZvbi ? withHeadlessDeps, # Teletext support

  # Licensing options (yes some are listed twice, filters and such are not listed)
  withGPL ? true,
  withVersion3 ? true, # When withGPL is set this implies GPLv3 otherwise it is LGPLv3
  withGPLv3 ? withGPL && withVersion3,
  withUnfree ? false,

  # Build options
  withSmallBuild ? false, # Optimize for size instead of speed
  withRuntimeCPUDetection ? true, # Detect CPU capabilities at runtime (disable to compile natively)
  withGrayscale ? withFullDeps, # Full grayscale support
  withSwscaleAlpha ? buildSwscale, # Alpha channel support in swscale. You probably want this when buildSwscale.
  withHardcodedTables ? withHeadlessDeps, # Hardcode decode tables instead of runtime generation
  withSafeBitstreamReader ? withHeadlessDeps, # Buffer boundary checking in bitreaders
  withMultithread ? true, # Multithreading via pthreads/win32 threads
  withNetwork ? withHeadlessDeps, # Network support
  withPixelutils ? withHeadlessDeps, # Pixel utils in libavutil
  withStatic ? stdenv.hostPlatform.isStatic,
  withShared ? !stdenv.hostPlatform.isStatic,
  withPic ? true,
  withThumb ? false, # On some ARM platforms

  # Program options
  buildFfmpeg ? withHeadlessDeps, # Build ffmpeg executable
  buildFfplay ? withSmallDeps, # Build ffplay executable
  buildFfprobe ? withHeadlessDeps, # Build ffprobe executable
  buildQtFaststart ? withFullDeps, # Build qt-faststart executable
  withBin ? buildFfmpeg || buildFfplay || buildFfprobe || buildQtFaststart,
  # Library options
  buildAvcodec ? withHeadlessDeps, # Build avcodec library
  buildAvdevice ? withHeadlessDeps, # Build avdevice library
  buildAvfilter ? withHeadlessDeps, # Build avfilter library
  buildAvformat ? withHeadlessDeps, # Build avformat library
  # Deprecated but depended upon by some packages.
  # https://github.com/NixOS/nixpkgs/pull/211834#issuecomment-1417435991)
  buildAvresample ? withHeadlessDeps && lib.versionOlder version "5", # Build avresample library
  buildAvutil ? withHeadlessDeps, # Build avutil library
  # Libpostproc is only available on versions lower than 8.0
  # https://code.ffmpeg.org/FFmpeg/FFmpeg/commit/8c920c4c396163e3b9a0b428dd550d3c986236aa
  buildPostproc ? withHeadlessDeps && lib.versionOlder version "8.0", # Build postproc library
  buildSwresample ? withHeadlessDeps, # Build swresample library
  buildSwscale ? withHeadlessDeps, # Build swscale library
  withLib ?
    buildAvcodec
    || buildAvdevice
    || buildAvfilter
    || buildAvformat
    || buildAvutil
    || buildPostproc
    || buildSwresample
    || buildSwscale,
  # Documentation options
  withDocumentation ? withHtmlDoc || withManPages || withPodDoc || withTxtDoc,
  withHtmlDoc ? withHeadlessDeps && lib.versionAtLeast version "6", # HTML documentation pages
  withManPages ? withHeadlessDeps && lib.versionAtLeast version "6", # Man documentation pages
  withPodDoc ? withHeadlessDeps && lib.versionAtLeast version "6", # POD documentation pages
  withTxtDoc ? withHeadlessDeps && lib.versionAtLeast version "6", # Text documentation pages
  # Whether a "doc" output will be produced. Note that withManPages does not produce
  # a "doc" output because its files go to "man".
  withDoc ? withDocumentation && (withHtmlDoc || withPodDoc || withTxtDoc),

  # Developer options
  withDebug ? false,
  withOptimisations ? true,
  withExtraWarnings ? false,
  withStripping ? false,

  # External libraries options
  alsa-lib,
  amf,
  amf-headers,
  aribb24,
  avisynthplus,
  bzip2,
  celt,
  chromaprint,
  codec2,
  dav1d,
  davs2,
  fdk_aac,
  flite,
  fontconfig,
  freetype,
  frei0r,
  fribidi,
  game-music-emu,
  gmp,
  gnutls,
  gsm,
  harfbuzz,
  intel-media-sdk,
  kvazaar,
  ladspa-header,
  lame,
  lcevcdec,
  lcms2,
  libaom,
  libaribcaption,
  libass,
  libbluray,
  libbs2b,
  libcaca,
  libcdio,
  libcdio-paranoia,
  libdc1394,
  libdrm,
  libdvdnav,
  libdvdread,
  libGL,
  libGLU,
  libiconv,
  libilbc,
  libjack2,
  libjxl,
  liblc3,
  libmodplug,
  libmysofa,
  libopenmpt,
  libopus,
  libplacebo,
  libplacebo_5,
  libpulseaudio,
  libraw1394,
  librist,
  librsvg,
  libssh,
  libtensorflow,
  libtheora,
  libv4l,
  libva,
  libva-minimal,
  libvdpau,
  libvmaf,
  libvorbis,
  libvpl,
  libvpx,
  libwebp,
  libx11,
  libxcb,
  libxext,
  libxml2,
  libxv,
  nv-codec-headers,
  nv-codec-headers-12,
  ocl-icd, # OpenCL ICD
  openal,
  openapv,
  opencl-headers, # OpenCL headers
  opencore-amr,
  openh264,
  openjpeg,
  qrencode,
  quirc,
  rav1e,
  rtmpdump,
  rubberband,
  twolame,
  samba,
  SDL2,
  shaderc,
  shine,
  snappy,
  soxr,
  speex,
  srt,
  svt-av1,
  uavs3d,
  vid-stab,
  vo-amrwbenc,
  vulkan-headers,
  vulkan-loader,
  vvenc,
  whisper-cpp,
  x264,
  x265,
  xavs,
  xavs2,
  xevd,
  xeve,
  xvidcore,
  xz,
  zeromq,
  zimg,
  zlib,
  zvbi,
  # Darwin
  apple-sdk_15,
  xcode, # unfree contains metalcc and metallib
  # Cuda Packages
  cuda_cudart,
  cuda_nvcc,
  libnpp,
  # Testing
  runCommand,
  testers,
}:

/*
  Maintainer notes:

  Version bumps:
  It should always be safe to bump patch releases (e.g. 2.1.x, x being a patch release)
  If adding a new branch, note any configure flags that were added, changed, or deprecated/removed
    and make the necessary changes.

  Known issues:
  Cross-compiling will disable features not present on host OS
    (e.g. dxva2 support [DirectX] will not be enabled unless natively compiled on Cygwin)
*/

let
  inherit (lib)
    optional
    optionals
    optionalString
    enableFeature
    versionOlder
    versionAtLeast
    ;

  regularFeatureIf = available: enabled: configureName: package: {
    inherit
      available
      enabled
      configureName
      package
      ;
    configureFlags = optionals available [ (enableFeature enabled configureName) ];
    buildInputs = optionals enabled [ package ];
  };
  regularFeature = regularFeatureIf true;

  # Keep regular option -> configure flag -> build input relationships together.
  # Literal rows are intentional exceptions for shared or multiple inputs, version
  # alternatives, CUDA toolchains, or configure-only features.
  featureSpecs = finalVersion: [
    (regularFeature withAlsa "alsa" alsa-lib)
    (regularFeature withAmf "amf" amf-headers)
    (regularFeature withAom "libaom" libaom)
    (regularFeature withAribb24 "libaribb24" aribb24)
    (regularFeatureIf (versionAtLeast version "6.1") withAribcaption "libaribcaption" libaribcaption)
    (regularFeature withAss "libass" libass)
    (regularFeature withAvisynth "avisynth" avisynthplus)
    (regularFeature withBluray "libbluray" libbluray)
    (regularFeature withBs2b "libbs2b" libbs2b)
    (regularFeature withBzlib "bzlib" bzip2)
    (regularFeature withCaca "libcaca" libcaca)
    {
      configureFlags = [ (enableFeature withCdio "libcdio") ];
      buildInputs = optionals withCdio [
        libcdio
        libcdio-paranoia
      ];
    }
    (regularFeature withCelt "libcelt" celt)
    (regularFeature withChromaprint "chromaprint" chromaprint)
    (regularFeature withCodec2 "libcodec2" codec2)
    {
      configureFlags = [ (enableFeature withCuda "cuda") ];
      buildInputs = [ ];
    }
    {
      configureFlags = [ (enableFeature withCudaLLVM "cuda-llvm") ];
      buildInputs = [ ];
    }
    {
      configureFlags = [ (enableFeature withCudaNVCC "cuda-nvcc") ];
      buildInputs = optionals withCudaNVCC [
        cuda_cudart
        cuda_nvcc
      ];
    }
    {
      configureFlags = [ (enableFeature withCuvid "cuvid") ];
      buildInputs = [ ];
    }
    (regularFeature withDav1d "libdav1d" dav1d)
    (regularFeature withDavs2 "libdavs2" davs2)
    {
      configureFlags = [ (enableFeature withDc1394 "libdc1394") ];
      buildInputs = optionals withDc1394 (
        [ libdc1394 ] ++ optional stdenv.hostPlatform.isLinux libraw1394
      );
    }
    (regularFeature withDrm "libdrm" libdrm)
    (regularFeatureIf (versionAtLeast version "7") withDvdnav "libdvdnav" libdvdnav)
    (regularFeatureIf (versionAtLeast version "7") withDvdread "libdvdread" libdvdread)
    (regularFeature withFdkAac "libfdk-aac" fdk_aac)
    {
      configureFlags = [ (enableFeature withNvcodec "ffnvcodec") ];
      buildInputs = optionals withNvcodec [
        (if versionAtLeast version "6" then nv-codec-headers-12 else nv-codec-headers)
      ];
    }
    (regularFeature withFlite "libflite" flite)
    {
      configureFlags = [
        (enableFeature withFontconfig "fontconfig")
        (enableFeature withFontconfig "libfontconfig")
      ];
      buildInputs = optionals withFontconfig [ fontconfig ];
    }
    (regularFeature withFreetype "libfreetype" freetype)
    (regularFeature withFrei0r "frei0r" frei0r)
    (regularFeature withFribidi "libfribidi" fribidi)
    (regularFeature withGme "libgme" game-music-emu)
    (regularFeature withGmp "gmp" gmp)
    (regularFeature withGnutls "gnutls" gnutls)
    (regularFeature withGsm "libgsm" gsm)
    (regularFeatureIf (versionAtLeast version "6.1") withHarfbuzz "libharfbuzz" harfbuzz)
    (regularFeature withIconv "iconv" libiconv)
    (regularFeature withIlbc "libilbc" libilbc)
    (regularFeature withJack "libjack" libjack2)
    (regularFeatureIf (versionAtLeast finalVersion "5.0") withJxl "libjxl" libjxl)
    (regularFeature withKvazaar "libkvazaar" kvazaar)
    (regularFeature withLadspa "ladspa" ladspa-header)
    (regularFeatureIf (versionAtLeast version "7.1") withLc3 "liblc3" liblc3)
    (regularFeatureIf (versionAtLeast version "7.1") withLcevcdec "liblcevc-dec" lcevcdec)
    (regularFeatureIf (versionAtLeast version "5.1") withLcms2 "lcms2" lcms2)
    (regularFeature withLzma "lzma" xz)
    {
      configureFlags = optionals (versionAtLeast version "5.0") [ (enableFeature withMetal "metal") ];
      buildInputs = [ ];
    }
    (regularFeature withMfx "libmfx" intel-media-sdk)
    (regularFeature withModplug "libmodplug" libmodplug)
    (regularFeature withMp3lame "libmp3lame" lame)
    (regularFeature withMysofa "libmysofa" libmysofa)
    {
      configureFlags = [ (enableFeature withNpp "libnpp") ];
      buildInputs = optionals withNpp [
        libnpp
        cuda_cudart
        cuda_nvcc
      ];
    }
    {
      configureFlags = [ (enableFeature withNvdec "nvdec") ];
      buildInputs = [ ];
    }
    {
      configureFlags = [ (enableFeature withNvenc "nvenc") ];
      buildInputs = [ ];
    }
    (regularFeature withOpenal "openal" openal)
    (regularFeatureIf (versionAtLeast version "8.0") withOpenapv "liboapv" openapv)
    {
      configureFlags = [ (enableFeature withOpencl "opencl") ];
      buildInputs = optionals withOpencl [
        ocl-icd
        opencl-headers
      ];
    }
    {
      configureFlags = [
        (enableFeature withOpencoreAmrnb "libopencore-amrnb")
        (enableFeature withOpencoreAmrwb "libopencore-amrwb")
      ];
      buildInputs = optionals (withOpencoreAmrnb || withOpencoreAmrwb) [ opencore-amr ];
    }
    {
      configureFlags = [ (enableFeature withOpengl "opengl") ];
      buildInputs = optionals withOpengl [
        libGL
        libGLU
      ];
    }
    (regularFeature withOpenh264 "libopenh264" openh264)
    (regularFeature withOpenjpeg "libopenjpeg" openjpeg)
    (regularFeature withOpenmpt "libopenmpt" libopenmpt)
    (regularFeature withOpus "libopus" libopus)
    {
      configureFlags = optionals (versionAtLeast version "5.0") [
        (enableFeature withPlacebo "libplacebo")
      ];
      buildInputs = optionals withPlacebo [
        (if versionAtLeast version "6.1" then libplacebo else libplacebo_5)
        vulkan-headers
      ];
    }
    (regularFeature withPulse "libpulse" libpulseaudio)
    (regularFeatureIf (versionAtLeast version "7") withQrencode "libqrencode" qrencode)
    (regularFeatureIf (versionAtLeast version "7") withQuirc "libquirc" quirc)
    (regularFeature withRav1e "librav1e" rav1e)
    (regularFeature withRist "librist" librist)
    (regularFeature withRtmp "librtmp" rtmpdump)
    (regularFeature withRubberband "librubberband" rubberband)
    (regularFeature withSamba "libsmbclient" samba)
    (regularFeature withSdl2 "sdl2" SDL2)
    (regularFeatureIf (versionAtLeast version "5.0") withShaderc "libshaderc" shaderc)
    (regularFeature withShine "libshine" shine)
    (regularFeature withSnappy "libsnappy" snappy)
    (regularFeature withSoxr "libsoxr" soxr)
    (regularFeature withSpeex "libspeex" speex)
    (regularFeature withSrt "libsrt" srt)
    (regularFeature withSsh "libssh" libssh)
    (regularFeature withSvg "librsvg" librsvg)
    (regularFeature withSvtav1 "libsvtav1" svt-av1)
    (regularFeature withTensorflow "libtensorflow" libtensorflow)
    (regularFeature withTheora "libtheora" libtheora)
    (regularFeature withTwolame "libtwolame" twolame)
    (regularFeature withUavs3d "libuavs3d" uavs3d)
    (regularFeature withV4l2 "libv4l2" libv4l)
    {
      configureFlags = [ (enableFeature withV4l2M2m "v4l2-m2m") ];
      buildInputs = [ ];
    }
    {
      configureFlags = [ (enableFeature withVaapi "vaapi") ];
      buildInputs = optionals withVaapi [ (if withSmallDeps then libva else libva-minimal) ];
    }
    (regularFeature withVdpau "vdpau" libvdpau)
    {
      configureFlags = optionals (versionAtLeast version "6.0") [ (enableFeature withVpl "libvpl") ];
      buildInputs = [ ];
    }
    (regularFeature withVidStab "libvidstab" vid-stab)
    (regularFeature withVmaf "libvmaf" libvmaf)
    (regularFeature withVoAmrwbenc "libvo-amrwbenc" vo-amrwbenc)
    (regularFeature withVorbis "libvorbis" libvorbis)
    {
      configureFlags = [ ];
      buildInputs = optionals withVpl [ libvpl ];
    }
    (regularFeature withVpx "libvpx" libvpx)
    {
      configureFlags = [ (enableFeature withVulkan "vulkan") ];
      buildInputs = optionals withVulkan [
        vulkan-headers
        vulkan-loader
      ];
    }
    (regularFeatureIf (versionAtLeast version "7.1") withVvenc "libvvenc" vvenc)
    (regularFeature withWebp "libwebp" libwebp)
    (regularFeatureIf (versionAtLeast version "8.0") withWhisper "whisper" whisper-cpp)
    (regularFeature withX264 "libx264" x264)
    (regularFeature withX265 "libx265" x265)
    (regularFeature withXavs "libxavs" xavs)
    (regularFeature withXavs2 "libxavs2" xavs2)
    {
      configureFlags = [
        (enableFeature withXcb "libxcb")
        (enableFeature withXcbShape "libxcb-shape")
        (enableFeature withXcbShm "libxcb-shm")
        (enableFeature withXcbxfixes "libxcb-xfixes")
      ];
      buildInputs = optionals withXcb [ libxcb ];
    }
    (regularFeatureIf (versionAtLeast version "7") withXevd "libxevd" xevd)
    (regularFeatureIf (versionAtLeast version "7") withXeve "libxeve" xeve)
    {
      configureFlags = [ (enableFeature withXlib "xlib") ];
      buildInputs = optionals withXlib [
        libx11
        libxv
        libxext
      ];
    }
    (regularFeature withXml2 "libxml2" libxml2)
    (regularFeature withXvid "libxvid" xvidcore)
    (regularFeature withZimg "libzimg" zimg)
    (regularFeature withZlib "zlib" zlib)
    (regularFeature withZmq "libzmq" zeromq)
    (regularFeature withZvbi "libzvbi" zvbi)
  ];

  featureConfigureFlags =
    finalVersion: lib.concatMap (feature: feature.configureFlags) (featureSpecs finalVersion);
  featureBuildInputs = lib.concatMap (feature: feature.buildInputs) (featureSpecs version);
in

assert lib.elem ffmpegVariant [
  "headless"
  "small"
  "full"
];

# Licensing dependencies
assert withGPLv3 -> withGPL && withVersion3;

# Build dependencies
assert withPixelutils -> buildAvutil;
assert !(withMfx && withVpl); # incompatible features
# Program dependencies
assert
  buildFfmpeg
  -> buildAvcodec && buildAvfilter && buildAvformat && (buildSwresample || buildAvresample);
assert
  buildFfplay
  ->
    buildAvcodec && buildAvformat && buildSwscale && (buildSwresample || buildAvresample) && withSdl2;
assert buildFfprobe -> buildAvcodec && buildAvformat;
# Library dependencies
assert buildAvcodec -> buildAvutil; # configure flag since 0.6
assert buildAvdevice -> buildAvformat && buildAvcodec && buildAvutil; # configure flag since 0.6
assert buildAvformat -> buildAvcodec && buildAvutil; # configure flag since 0.6
assert buildPostproc -> buildAvutil;
assert buildSwscale -> buildAvutil;

# External Library dependencies
assert (withCuda || withCuvid || withNvdec || withNvenc) -> withNvcodec;

stdenv.mkDerivation (
  finalAttrs:
  {
    pname = "ffmpeg" + (optionalString (ffmpegVariant != "small") "-${ffmpegVariant}");
    inherit version;
    src = source;

    postPatch = ''
      patchShebangs .
    ''
    + lib.optionalString withFrei0r ''
      substituteInPlace libavfilter/vf_frei0r.c \
        --replace /usr/local/lib/frei0r-1 ${frei0r}/lib/frei0r-1
      substituteInPlace doc/filters.texi \
        --replace /usr/local/lib/frei0r-1 ${frei0r}/lib/frei0r-1
    ''
    # https://code.ffmpeg.org/FFmpeg/FFmpeg/issues/22564, also fails on big-endian POWER
    + lib.optionalString (lib.versionAtLeast version "8.1" && stdenv.hostPlatform.isBigEndian) ''
      substituteInPlace tests/fate/vcodec.mak \
        --replace-fail \
          'FATE_VCODEC_SCALE-$(call ENCDEC, FFVHUFF, AVI) += ffvhuff444 ffvhuff420p12 ffvhuff422p10left ffvhuff444p16' \
          'FATE_VCODEC_SCALE-$(call ENCDEC, FFVHUFF, AVI) += ffvhuff444 ffvhuff422p10left ffvhuff444p16'
    '';

    patches =
      [ ]
      ++ optionals (lib.versionOlder version "5") [
        (fetchpatch2 {
          name = "rename_iszero";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/b27ae2c0b704e83f950980102bc3f12f9ec17cb0";
          hash = "sha256-l1t4LcUDSW757diNu69NzvjenW5Mxb5aYtXz64Yl9gs=";
        })
      ]
      ++ optionals (lib.versionAtLeast version "5.1") [
        ./nvccflags-cpp14.patch
      ]
      ++ optionals (lib.versionAtLeast version "7.0" && lib.versionOlder version "7.1.4") [
        (fetchpatch2 {
          name = "unbreak-hardcoded-tables.patch";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/1d47ae65bf6df91246cbe25c997b25947f7a4d1d";
          hash = "sha256-ulB5BujAkoRJ8VHou64Th3E94z6m+l6v9DpG7/9nYsM=";
        })
      ]
      ++ optionals (lib.versionOlder version "7.1.1" && lib.versions.major version != "5") [
        (fetchpatch2 {
          name = "texinfo-7.1.patch";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/4d9cdf82ee36a7da4f065821c86165fe565aeac2";
          hash = "sha256-BZsq1WI6OgtkCQE8koQu0CNcb5c8WgTu/LzQzu6ZLuo=";
        })
      ]
      ++ optionals (lib.versionOlder version "7" && stdenv.hostPlatform.isAarch32) [
        (fetchpatch2 {
          name = "binutils-2-43-compat.patch";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/654bd47716c4f36719fb0f3f7fd8386d5ed0b916";
          hash = "sha256-OLiQHKBNp2p63ZmzBBI4GEGz3WSSP+rMd8ITfZSVRgY=";
        })
      ]
      ++ optionals (lib.versionAtLeast version "7.1.1") [
        # Expose a private API for Chromium / Qt WebEngine.
        (fetchpatch2 {
          url = "https://gitlab.archlinux.org/archlinux/packaging/packages/ffmpeg/-/raw/a02c1a15706ea832c0d52a4d66be8fb29499801a/add-av_stream_get_first_dts-for-chromium.patch";
          hash = "sha256-DbH6ieJwDwTjKOdQ04xvRcSLeeLP2Z2qEmqeo8HsPr4=";
        })
      ]
      ++ optionals (lib.versionOlder version "7.1.2") [
        (fetchpatch2 {
          name = "unbreak-svt-av1-3.0.0.patch";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/d1ed5c06e3edc5f2b5f3664c80121fa55b0baa95";
          hash = "sha256-2NVkIhQVS1UQJVYuDdeH+ZvWYKVbtwW9Myu5gx7JnbA=";
        })
      ]
      ++ optionals (lib.versionAtLeast version "6" && lib.versionOlder version "7.1.4") [
        (fetchpatch2 {
          name = "svt-av1-4.0.0-compat.patch";
          url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/a5d4c398b411a00ac09d8fe3b66117222323844c";
          hash = "sha256-peIXXU5+5DRQc3Xdpz5V+xIN7Vohs0Dlal6mHiMryXc=";
        })
      ];

    configurePlatforms = [ ];
    setOutputFlags = false; # Only accepts some of them
    configureFlags = [
      #mingw64 is internally treated as mingw32, so 32 and 64 make no difference here
      "--target_os=${
        if stdenv.hostPlatform.isMinGW then "mingw64" else stdenv.hostPlatform.parsed.kernel.name
      }"
      "--arch=${stdenv.hostPlatform.parsed.cpu.name}"
      "--pkg-config=${buildPackages.pkg-config.targetPrefix}pkg-config"
      # Licensing flags
      (enableFeature withGPL "gpl")
      (enableFeature withVersion3 "version3")
      (enableFeature withUnfree "nonfree")
      # Build flags
      (enableFeature withStatic "static")
      (enableFeature withShared "shared")
      (enableFeature withPic "pic")
      (enableFeature withThumb "thumb")

      (enableFeature withSmallBuild "small")
      (enableFeature withRuntimeCPUDetection "runtime-cpudetect")
      (enableFeature withGrayscale "gray")
      (enableFeature withSwscaleAlpha "swscale-alpha")
      (enableFeature withHardcodedTables "hardcoded-tables")
      (enableFeature withSafeBitstreamReader "safe-bitstream-reader")

      (enableFeature (withMultithread && stdenv.hostPlatform.isUnix) "pthreads")
      (enableFeature (withMultithread && stdenv.hostPlatform.isWindows) "w32threads")
      "--disable-os2threads" # We don't support OS/2

      (enableFeature withNetwork "network")
      (enableFeature withPixelutils "pixelutils")

      "--datadir=${placeholder "data"}/share/ffmpeg"

      # Program flags
      (enableFeature buildFfmpeg "ffmpeg")
      (enableFeature buildFfplay "ffplay")
      (enableFeature buildFfprobe "ffprobe")
    ]
    ++ optionals withBin [
      "--bindir=${placeholder "bin"}/bin"
    ]
    ++ [
      # Library flags
      (enableFeature buildAvcodec "avcodec")
      (enableFeature buildAvdevice "avdevice")
      (enableFeature buildAvfilter "avfilter")
      (enableFeature buildAvformat "avformat")
    ]
    ++ optionals (lib.versionOlder version "5") [
      # Ffmpeg > 4 doesn't know about the flag anymore
      (enableFeature buildAvresample "avresample")
    ]
    ++ [
      (enableFeature buildAvutil "avutil")
    ]
    ++ optionals (lib.versionOlder version "8.0") [
      # FFMpeg >= 8 doesn't know about the flag anymore
      (enableFeature (buildPostproc && withGPL) "postproc")
    ]
    ++ [
      (enableFeature buildSwresample "swresample")
      (enableFeature buildSwscale "swscale")
    ]
    ++ optionals withLib [
      "--libdir=${placeholder "lib"}/lib"
      "--incdir=${placeholder "dev"}/include"
    ]
    ++ [
      # Documentation flags
      (enableFeature withDocumentation "doc")
      (enableFeature withHtmlDoc "htmlpages")
      (enableFeature withManPages "manpages")
    ]
    ++ optionals withManPages [
      "--mandir=${placeholder "man"}/share/man"
    ]
    ++ [
      (enableFeature withPodDoc "podpages")
      (enableFeature withTxtDoc "txtpages")
    ]
    ++ optionals withDoc [
      "--docdir=${placeholder "doc"}/share/doc/ffmpeg"
    ]
    ++ featureConfigureFlags finalAttrs.version
    ++ [
      # Developer flags
      (enableFeature withDebug "debug")
      (enableFeature withOptimisations "optimizations")
      (enableFeature withExtraWarnings "extra-warnings")
      (enableFeature withStripping "stripping")
    ]
    ++ optionals (stdenv.hostPlatform.isPower) [
      # FFmpeg expects us to pass `--cpu=` to pick a specific feature set to compile for. If unset, it defaults to `generic`.
      # For POWER, the default doesn't produce baseline-compliant settings. Passing a baseline-like CPU as a target doesn't
      # produce entirely correct settings either - POWER4 leaves AltiVec enabled, but that's only guaranteed with POWER6.
      # Just configure together everything on our own.

      # Easy: Only ppc64le's baseline is recent enough to guarantee all of these.
      (enableFeature (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian) "altivec")
      (enableFeature (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian) "vsx")
      (enableFeature (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian) "power8")
      (enableFeature (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian) "ldbrx")

      # Instructions that are highly specific to that series of 32-bit embedded CPUs. Never try to enable them.
      (enableFeature false "ppc4xx")

      # I *think* enabling this on 64-bit POWER is correct? Struggling to find much info on when/where this was introduced.
      # Definitely present on the Apple G5, and likely Freescale e5500/e6500 as well.
      (enableFeature (stdenv.hostPlatform.isPower64) "dcbzl")
    ]
    ++ optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      "--cross-prefix=${stdenv.cc.targetPrefix}"
      "--enable-cross-compile"
      "--host-cc=${buildPackages.stdenv.cc}/bin/cc"
    ]
    ++ optionals stdenv.cc.isClang [
      "--cc=${stdenv.cc.targetPrefix}clang"
      "--cxx=${stdenv.cc.targetPrefix}clang++"
    ]
    ++ optionals withCudaLLVM [
      # Unwrapped compiler because it will be retargeted and used freestanding with --cuda-device-only.
      "--nvcc=${lib.getExe buildPackages.clang.cc}"
    ]
    ++ optionals withMetal [
      "--metalcc=${xcode}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal"
      "--metallib=${xcode}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metallib"
    ];

    # ffmpeg embeds the configureFlags verbatim in its binaries and because we
    # configure binary, include, library dir etc., this causes references in
    # outputs where we don't want them. Patch the generated config.h to remove all
    # such references except for data.
    postConfigure =
      let
        toStrip =
          map placeholder (lib.remove "data" finalAttrs.outputs) # We want to keep references to the data dir.
          ++ lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) buildPackages.stdenv.cc
          ++ lib.optional withCudaLLVM buildPackages.clang.cc
          ++ lib.optional withMetal xcode;
      in
      "remove-references-to ${lib.concatMapStringsSep " " (o: "-t ${o}") toStrip} config.h";

    strictDeps = true;

    nativeBuildInputs = [
      removeReferencesTo
      addDriverRunpath
      perl
      pkg-config
    ]
    ++ optionals stdenv.hostPlatform.isx86 [ nasm ]
    # Texinfo version 7.1 introduced breaking changes, which older versions of ffmpeg do not handle.
    ++ optionals (lib.versionAtLeast version "6") [ texinfo ]
    ++ optionals withCudaNVCC [ cuda_nvcc ];

    buildInputs = [ ] ++ optionals stdenv.hostPlatform.isDarwin [ apple-sdk_15 ] ++ featureBuildInputs;

    buildFlags = [ "all" ] ++ optional buildQtFaststart "tools/qt-faststart"; # Build qt-faststart executable

    env = lib.optionalAttrs stdenv.cc.isGNU {
      NIX_CFLAGS_COMPILE = toString [
        "-Wno-error=incompatible-pointer-types"
        "-Wno-error=int-conversion"
      ];
    };

    # tests linking broken with shaderc after https://github.com/NixOS/nixpkgs/pull/477464/changes/5a47b12dfcd1b909ba35778a866394430054319a
    doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform && !withShaderc;

    # Fails with SIGABRT otherwise FIXME: Why?
    checkPhase =
      let
        ldLibraryPathEnv = if stdenv.hostPlatform.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";
        libsToLink =
          [ ]
          ++ optional buildAvcodec "libavcodec"
          ++ optional buildAvdevice "libavdevice"
          ++ optional buildAvfilter "libavfilter"
          ++ optional buildAvformat "libavformat"
          ++ optional buildAvresample "libavresample"
          ++ optional buildAvutil "libavutil"
          ++ optional buildPostproc "libpostproc"
          ++ optional buildSwresample "libswresample"
          ++ optional buildSwscale "libswscale";
      in
      ''
        ${ldLibraryPathEnv}="${lib.concatStringsSep ":" libsToLink}" make check -j$NIX_BUILD_CORES
      '';

    outputs =
      optionals withBin [ "bin" ] # The first output is the one that gets symlinked by default!
      ++ optionals withLib [
        "lib"
        "dev"
      ]
      ++ optionals withDoc [ "doc" ]
      ++ optionals withManPages [ "man" ]
      ++ [
        "data"
        "out"
      ] # We need an "out" output because we get an error otherwise. It's just an empty dir.
    ;

    postInstall = optionalString buildQtFaststart ''
      install -D tools/qt-faststart -t $bin/bin
    '';

    # Set RUNPATH so that libnvcuvid and libcuda in /run/opengl-driver(-32)/lib can be found.
    # See the explanation in addDriverRunpath.
    postFixup =
      optionalString (stdenv.hostPlatform.isLinux && withLib) ''
        addDriverRunpath ${placeholder "lib"}/lib/libavcodec.so
        addDriverRunpath ${placeholder "lib"}/lib/libavutil.so
      ''
      # https://trac.ffmpeg.org/ticket/10809
      + optionalString (versionAtLeast version "5.0" && withVulkan && !stdenv.hostPlatform.isMinGW) ''
        patchelf $lib/lib/libavcodec.so --add-needed libvulkan.so --add-rpath ${
          lib.makeLibraryPath [ vulkan-loader ]
        }
      '';

    enableParallelBuilding = true;

    passthru.tests = {
      pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
      feature-spec =
        let
          regularFeatures = lib.filter (feature: feature ? configureName && feature.available) (
            featureSpecs finalAttrs.version
          );
          expectedLine =
            feature:
            let
              flag = enableFeature feature.enabled feature.configureName;
              input = optionalString feature.enabled "\t${feature.package.name}";
            in
            "${flag}${input}";
          actualLine =
            feature:
            let
              flag = enableFeature feature.enabled feature.configureName;
              actualFlag = if lib.elem flag finalAttrs.configureFlags then flag else "missing: ${flag}";
              actualInput = optionalString feature.enabled "\t${
                if lib.elem feature.package finalAttrs.buildInputs then feature.package.name else "missing input"
              }";
            in
            "${actualFlag}${actualInput}";
        in
        runCommand "ffmpeg-regular-feature-spec"
          {
            actual = builtins.toFile "ffmpeg-regular-feature-spec-actual" (
              lib.concatMapStringsSep "\n" actualLine regularFeatures
            );
            expected = builtins.toFile "ffmpeg-regular-feature-spec-expected" (
              lib.concatMapStringsSep "\n" expectedLine regularFeatures
            );
          }
          ''
            diff -u "$expected" "$actual"
            touch "$out"
          '';
    };

    meta = {
      description = "Complete, cross-platform solution to record, convert and stream audio and video";
      homepage = "https://www.ffmpeg.org/";
      changelog = "https://github.com/FFmpeg/FFmpeg/blob/n${version}/Changelog";
      longDescription = ''
        FFmpeg is the leading multimedia framework, able to decode, encode, transcode,
        mux, demux, stream, filter and play pretty much anything that humans and machines
        have created. It supports the most obscure ancient formats up to the cutting edge.
        No matter if they were designed by some standards committee, the community or
        a corporation.
      '';
      donationPage = "https://ffmpeg.org/donations.html";
      license =
        with lib.licenses;
        [ lgpl21Plus ]
        ++ optional withGPL gpl2Plus
        ++ optional withVersion3 lgpl3Plus
        ++ optional withGPLv3 gpl3Plus
        ++ optional withUnfree unfreeRedistributable
        ++ optional (withGPL && withUnfree) unfree;
      pkgConfigModules =
        [ ]
        ++ optional buildAvcodec "libavcodec"
        ++ optional buildAvdevice "libavdevice"
        ++ optional buildAvfilter "libavfilter"
        ++ optional buildAvformat "libavformat"
        ++ optional buildAvresample "libavresample"
        ++ optional buildAvutil "libavutil"
        ++ optional buildPostproc "libpostproc"
        ++ optional buildSwresample "libswresample"
        ++ optional buildSwscale "libswscale";
      platforms = lib.platforms.all;
      # See https://github.com/NixOS/nixpkgs/pull/295344#issuecomment-1992263658
      broken = stdenv.hostPlatform.isMinGW && stdenv.hostPlatform.is64bit;
      maintainers = with lib.maintainers; [
        atemu
        jopejoe1
        emily
      ];
      mainProgram = "ffmpeg";
    };
  }
  // lib.optionalAttrs withCudaLLVM {
    # remove once https://github.com/NixOS/nixpkgs/issues/318674 is addressed properly
    hardeningDisable = [
      "pacret"
      "shadowstack"
      "zerocallusedregs"
    ];
  }
)
