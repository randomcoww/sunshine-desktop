### Container for Steam over Sunshine

Originally based on https://github.com/Steam-Headless/docker-steam-headless/tree/master but has changed quite a bit now.

Currently migrating to Wayland and isn't able to fully use the Nvidia GPU. Nvidia graphics acceleration works in applications like games, but desktop rendering and Sunshine encoding seems to only work on an alternate GPU with non proprietary drivers.

My environment is also a little unique and some common modules like `nvidia-drm` are currently not installed with the driver, so this may be the issue.

#### Args example:

Entrypoint runs `tini --`

```yaml
- bash
- -c
- |
  set -e

  ## Driver ##

  mkdir -p $HOME/nvidia
  targetarch=$(arch)
  driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader --id=0)
  driver_file=$HOME/nvidia/NVIDIA-Linux-$targetarch-$driver_version.run

  NVIDIA_DRIVER_BASE_URL=${NVIDIA_DRIVER_BASE_URL:-https://us.download.nvidia.com/XFree86/${targetarch/x86_64/Linux-x86_64}}
  curl -L --skip-existing -o "$driver_file" \
    $NVIDIA_DRIVER_BASE_URL/$driver_version/NVIDIA-Linux-$targetarch-$driver_version.run

  chmod +x "$driver_file"

  # TODO: try removing --no-install-libglvnd when https://github.com/LizardByte/Sunshine/issues/4050 is resolved
  "$driver_file" \
    --silent \
    --accept-license \
    --skip-depmod \
    --skip-module-unload \
    --no-kernel-modules \
    --no-kernel-module-source \
    --install-compat32-libs \
    --no-nouveau-check \
    --no-nvidia-modprobe \
    --no-systemd \
    --no-distro-scripts \
    --no-rpms \
    --no-backup \
    --no-check-for-alternate-installs \
    --no-libglx-indirect \
    --no-install-libglvnd

  ## User ##

  mkdir -p $HOME $XDG_RUNTIME_DIR
  chown $UID:$UID $HOME $XDG_RUNTIME_DIR

  useradd $USER -d $HOME -m -u $UID
  usermod -G wheel,video,input,render,dbus,seat $USER

  ## Udev ##

  /lib/systemd/systemd-udevd &

  ## Seatd ##

  seatd -u $USER &

  runuser -p -u $USER -- bash <<EOT
  set -e
  cd $HOME

  ## Pulseaudio ##

  pulseaudio \
    --log-level=0 \
    --daemonize=true \
    --disallow-exit=true \
    --log-target=stderr \
    --exit-idle-time=-1

  ## Sway ##

  sway &
  while ! wlr-randr >/dev/null 2>&1; do
  sleep 1
  done

  ## Sunshine ##

  exec sunshine \
    origin_web_ui_allowed=wan \
    port=$SUNSHINE_PORT \
    file_apps=/etc/sunshine/apps.json \
    upnp=off
  EOT
  EOF
```

Latest Sunshine release

```bash
curl -s https://api.github.com/repos/LizardByte/Sunshine/tags | grep name | head -1 | cut -d '"' -f 4 | tr -d 'v'
```