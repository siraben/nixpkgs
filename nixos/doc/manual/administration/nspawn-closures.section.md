# Running a configuration with `systemd-nspawn` {#sec-nspawn-system-closure}

A NixOS system closure is a boot generation, not a complete root file system.
In particular, its `etc` entry is an absolute symlink into the Nix store and
its init program is at `init`, rather than at one of the conventional paths
that `systemd-nspawn --boot` searches. Consequently, passing a system closure
directly as `systemd-nspawn --boot --directory=...` is not supported. The
`os-release` check performed by `systemd-nspawn` resolves paths relative to the
container root, so the store symlink is deliberately not accepted as proof
that the closure is an operating-system tree.

Every NixOS configuration instead exposes a container launcher through
`system.build.nspawn`. For a flake configuration named `myhost` whose
`networking.hostName` is also `myhost`, build and run it as follows:

```ShellSession
$ nix build .#nixosConfigurations.myhost.config.system.build.nspawn
$ sudo ./result/bin/run-myhost-nspawn
```

The launcher creates a writable, initially empty root directory, makes the
host's Nix store available read-only, and passes the NixOS init program to
`systemd-nspawn` explicitly. It does not disable `systemd-nspawn`'s
operating-system-tree validation globally. The default root directory is
`./myhost-root`; set the `RUN_NSPAWN_ROOT_DIR` environment variable to override
it when running the launcher. System specialisations are not included in the
container variant because their activation requires creating privileged
wrappers, which the nspawn launcher cannot do in the Nix build sandbox.

Container-specific changes can be made without changing the normal system:

```nix
{ lib, ... }:
{
  virtualisation.nspawnVariant = {
    networking.hostName = lib.mkForce "sandbox";
    virtualisation.rootDir = "/var/lib/my-sandbox";
    virtualisation.systemd-nspawn.options = [ "--bind=/srv/data" ];
  };
}
```

In `systemd-nspawn` terminology this uses explicit-command mode rather than
`--boot` mode. The explicit command is still the NixOS init process running as
PID 1, so the container performs normal NixOS activation and reaches its
systemd targets. In contrast, passing a shell or another program after `--`
only runs that program and does not boot the NixOS configuration.
