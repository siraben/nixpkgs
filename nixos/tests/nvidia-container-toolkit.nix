{ pkgs, lib, ... }:
let
  testCDIScript = pkgs.writeShellScriptBin "test-cdi" ''
    die() {
      echo "$1"
      exit 1
    }

    check_file_referential_integrity() {
      echo "checking $1 referential integrity"
      ( ${pkgs.glibc.bin}/bin/ldd "$1" | ${lib.getExe pkgs.gnugrep} "not found" &> /dev/null ) && return 1
      return 0
    }

    check_directory_referential_integrity() {
      ${lib.getExe pkgs.findutils} "$1" -type f -print0 | while read -d $'\0' file; do
        if [[ $(${lib.getExe pkgs.file} "$file" | ${lib.getExe pkgs.gnugrep} ELF) ]]; then
          check_file_referential_integrity "$file" || exit 1
        else
          echo "skipping $file: not an ELF file"
        fi
      done
    }

    check_directory_referential_integrity "/usr/bin" || exit 1
    check_directory_referential_integrity "${pkgs.addDriverRunpath.driverLink}" || exit 1
    check_directory_referential_integrity "/usr/local/nvidia" || exit 1
  '';
  testContainerImage = pkgs.dockerTools.buildImage {
    name = "cdi-test";
    tag = "latest";
    config = {
      Cmd = [ (lib.getExe testCDIScript) ];
    };
    copyToRoot = with pkgs.dockerTools; [
      usrBinEnv
      binSh
    ];
  };
  emptyCDISpec = ''
    {
      "cdiVersion": "0.5.0",
      "kind": "nvidia.com/gpu",
      "devices": [
        {
          "name": "all",
          "containerEdits": {
            "deviceNodes": [
              {
                "path": "/dev/urandom"
              }
            ],
            "hooks": [],
            "mounts": []
          }
        }
      ],
      "containerEdits": {
        "deviceNodes": [],
        "hooks": [],
        "mounts": []
      }
    }
  '';
  mkNvidiaContainerToolkit =
    {
      requireDriver ? false,
    }:
    pkgs.stdenv.mkDerivation {
      pname = "nvidia-ctk-dummy";
      version = "1.0.0";
      dontUnpack = true;
      dontBuild = true;

      inherit emptyCDISpec;
      passAsFile = [ "emptyCDISpec" ];

      installPhase = ''
        mkdir -p $out/bin $out/share/nvidia-container-toolkit
        cp "$emptyCDISpecPath" "$out/share/nvidia-container-toolkit/spec.json"
        cat << EOF > "$out/bin/nvidia-ctk"
        #!${pkgs.runtimeShell}
        echo invocation >> /run/nvidia-ctk-invocations
        ${lib.optionalString requireDriver ''
          set -- /sys/bus/pci/drivers/nvidia/????:??:??.?
          if [ ! -e "\$1" ] || [ -e /run/nvidia-ctk-fail ]; then
            echo "failed to initialize NVML: Driver Not Loaded" >&2
            exit 1
          fi
        ''}
        cat "$out/share/nvidia-container-toolkit/spec.json"
        EOF
        chmod +x $out/bin/nvidia-ctk
      '';
      meta.mainProgram = "nvidia-ctk";
    };
  nvidia-container-toolkit = {
    enable = true;
    package = mkNvidiaContainerToolkit { };
    suppressNvidiaDriverAssertion = true;
  };
in
{
  name = "nvidia-container-toolkit";
  meta = with lib.maintainers; {
    maintainers = [
      ereslibre
      christoph-heiss
    ];
  };
  defaults =
    { config, ... }:
    {
      environment.systemPackages = with pkgs; [ jq ];
      virtualisation.diskSize = lib.mkDefault 10240;
      virtualisation.containers = {
        containersConf.settings.engine.cdi_spec_dirs = [ "/var/run/cdi" ];
        enable = lib.mkDefault true;
      };
      hardware = {
        inherit nvidia-container-toolkit;
        nvidia = {
          open = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable.open;
        };
        graphics.enable = lib.mkDefault true;
      };
    };
  nodes = {
    no-gpus = {
      virtualisation.containers.enable = false;
    };

    one-gpu =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ podman ];
        hardware.graphics.enable = true;
      };

    one-gpu-invalid-host-paths = {
      hardware.nvidia-container-toolkit.mounts = [
        {
          hostPath = "/non-existant-path";
          containerPath = "/some/path";
        }
      ];
    };

    hotplugged-gpu =
      { config, pkgs, ... }:
      let
        kernel = config.boot.kernelPackages.kernel;
        fakeNvidiaDriver =
          pkgs.runCommandCC "fake-nvidia-driver"
            {
              hardeningDisable = [ "pic" ];
              nativeBuildInputs = kernel.moduleBuildDependencies;
            }
            ''
              cat > Makefile <<'EOF'
              obj-m += fake_nvidia.o
              EOF
              cat > fake_nvidia.c <<'EOF'
              #include <linux/module.h>
              #include <linux/pci.h>

              static int fake_nvidia_probe(struct pci_dev *pdev, const struct pci_device_id *id)
              {
                  return 0;
              }

              static const struct pci_device_id fake_nvidia_ids[] = {
                  { PCI_DEVICE(0x1b36, 0x0005) },
                  { }
              };
              MODULE_DEVICE_TABLE(pci, fake_nvidia_ids);

              static struct pci_driver fake_nvidia_driver = {
                  .name = "nvidia",
                  .id_table = fake_nvidia_ids,
                  .probe = fake_nvidia_probe,
              };
              module_pci_driver(fake_nvidia_driver);

              MODULE_LICENSE("GPL");
              EOF
              make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M="$PWD" modules
              install -D fake_nvidia.ko "$out/lib/modules/${kernel.modDirVersion}/fake_nvidia.ko"
            '';
      in
      {
        boot = {
          extraModulePackages = [ fakeNvidiaDriver ];
          kernelModules = [ "fake_nvidia" ];
        };
        hardware.nvidia-container-toolkit.package = lib.mkForce (mkNvidiaContainerToolkit {
          requireDriver = true;
        });
        virtualisation = {
          containers.enable = false;
          qemu.options = [ "-device pcie-root-port,id=nvidia-port" ];
        };
      };
  };
  testScript = ''
    from datetime import timedelta

    start_all()

    with subtest("Generate an empty CDI spec for a machine with no Nvidia GPUs"):
      no_gpus.wait_for_unit("nvidia-container-toolkit-cdi-generator.service")
      no_gpus.succeed("cat /var/run/cdi/nvidia-container-toolkit.json | jq")

    with subtest("Podman loads the generated CDI spec for a machine with an Nvidia GPU"):
      one_gpu.wait_for_unit("nvidia-container-toolkit-cdi-generator.service")
      one_gpu.succeed("cat /var/run/cdi/nvidia-container-toolkit.json | jq")
      one_gpu.succeed("podman load < ${testContainerImage}")
      one_gpu.succeed("podman run --pull=never --device=nvidia.com/gpu=all -v /run/opengl-driver:/run/opengl-driver:ro cdi-test:latest")

    # Issue: https://github.com/NixOS/nixpkgs/issues/319201
    with subtest("The generated CDI spec skips specified non-existant paths in the host"):
      one_gpu_invalid_host_paths.wait_for_unit("nvidia-container-toolkit-cdi-generator.service")
      one_gpu_invalid_host_paths.fail("grep 'non-existant-path' /var/run/cdi/nvidia-container-toolkit.json")

    with subtest("Regenerate the CDI spec after an Nvidia driver binds to a GPU"):
      hotplugged_gpu.wait_for_unit("multi-user.target")
      hotplugged_gpu.wait_until_succeeds(
          "systemctl is-failed nvidia-container-toolkit-cdi-generator.service",
          timeout=timedelta(seconds=30),
      )
      hotplugged_gpu.succeed("journalctl -u nvidia-container-toolkit-cdi-generator.service | grep -F 'Driver Not Loaded'")
      hotplugged_gpu.fail("test -s /var/run/cdi/nvidia-container-toolkit.json")

      hotplugged_gpu.send_monitor_command("device_add pci-testdev,id=nvidia-egpu,bus=nvidia-port")
      hotplugged_gpu.wait_until_succeeds(
          "test -e /sys/bus/pci/drivers/nvidia/0000:*", timeout=timedelta(seconds=30)
      )
      hotplugged_gpu.wait_until_succeeds(
          "systemctl is-active nvidia-container-toolkit-cdi-generator.service",
          timeout=timedelta(seconds=30),
      )
      hotplugged_gpu.succeed("jq -e '.kind == \"nvidia.com/gpu\"' /var/run/cdi/nvidia-container-toolkit.json")

      runtime_inode = hotplugged_gpu.succeed("stat -c %i /run/cdi").strip()
      active_enter = hotplugged_gpu.succeed(
          "systemctl show -P ActiveEnterTimestampMonotonic nvidia-container-toolkit-cdi-generator.service"
      ).strip()
      generation_count = int(hotplugged_gpu.succeed("wc -l < /run/nvidia-ctk-invocations"))
      hotplugged_gpu.send_monitor_command("device_del nvidia-egpu")
      hotplugged_gpu.wait_until_fails(
          "test -e /sys/bus/pci/drivers/nvidia/0000:*", timeout=timedelta(seconds=30)
      )
      hotplugged_gpu.send_monitor_command("device_add pci-testdev,id=nvidia-egpu,bus=nvidia-port")
      hotplugged_gpu.wait_until_succeeds(
          f"test $(wc -l < /run/nvidia-ctk-invocations) -gt {generation_count} "
          "&& test $(systemctl show -P SubState nvidia-container-toolkit-cdi-generator.service) = exited",
          timeout=timedelta(seconds=30),
      )
      hotplugged_gpu.succeed(f"test $(stat -c %i /run/cdi) -eq {runtime_inode}")
      hotplugged_gpu.succeed(
          "test $(systemctl show -P ActiveEnterTimestampMonotonic "
          f"nvidia-container-toolkit-cdi-generator.service) = {active_enter}"
      )

      spec_hash = hotplugged_gpu.succeed(
          "sha256sum /var/run/cdi/nvidia-container-toolkit.json | cut -d ' ' -f 1"
      ).strip()
      hotplugged_gpu.succeed("touch /run/nvidia-ctk-fail")
      hotplugged_gpu.fail("systemctl reload nvidia-container-toolkit-cdi-generator.service")
      hotplugged_gpu.succeed(
          f"test $(sha256sum /var/run/cdi/nvidia-container-toolkit.json | cut -d ' ' -f 1) = {spec_hash}"
      )
  '';
}
