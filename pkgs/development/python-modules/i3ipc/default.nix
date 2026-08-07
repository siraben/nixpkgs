{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  fetchpatch,
  coreutils,
  setuptools,
  python-xlib,
  fontconfig,
  pytestCheckHook,
  writableTmpDirAsHomeHook,
  pytest-asyncio,
  pytest-timeout,
  pytest-xvfb,
  i3,
  xvfb,
  xdpyinfo,
}:

buildPythonPackage rec {
  pname = "i3ipc";
  version = "2.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "altdesktop";
    repo = "i3ipc-python";
    tag = "v${version}";
    hash = "sha256-JRwipvIF1zL/x2A+xEJKEFV6BlDnv2Xt/eyIzVrSf40=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/altdesktop/i3ipc-python/commit/d14e7a681f0a3e5b55007b4e6b0d46c3c55ef86d.patch";
      hash = "sha256-GiKewxwGfDXvkHUtoTkubYwyQAhBEqs37HjwFD2NOHg=";
    })

    # Upstream expects a very old version of pytest-asyncio. This patch correctly
    # decorates async fixtures using pytest-asyncio and configures `loop_scope`
    # where needed.
    ./fix-async-tests.patch
  ];

  postPatch = ''
    substituteInPlace test/i3.config \
      --replace-fail /bin/true ${coreutils}/bin/true
  '';

  build-system = [ setuptools ];
  dependencies = [ python-xlib ];

  # Fontconfig error: Cannot load default config file
  env.FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  nativeCheckInputs = [
    pytestCheckHook
    writableTmpDirAsHomeHook
    pytest-asyncio
    pytest-timeout
    pytest-xvfb
    i3
    xdpyinfo
    xvfb
  ];

  disabledTestPaths = [
    # Timeout
    "test/test_shutdown_event.py::TestShutdownEvent::test_shutdown_event_reconnect"
    "test/aio/test_shutdown_event.py::TestShutdownEvent::test_shutdown_event_reconnect"
    # Flaky
    "test/test_window.py::TestWindow::test_detailed_window_event"
    "test/aio/test_workspace.py::TestWorkspace::test_workspace"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    # Times out during async fixture setup with Darwin's kqueue event loop
    "test/aio/test_event_exceptions.py::TestEventExceptions::test_event_exceptions"
  ];

  pythonImportsCheck = [ "i3ipc" ];

  meta = {
    description = "Improved Python library to control i3wm and sway";
    homepage = "https://github.com/altdesktop/i3ipc-python";
    changelog = "https://github.com/altdesktop/i3ipc-python/releases/tag/${src.tag}";
    license = lib.licenses.bsd3;
  };
}
