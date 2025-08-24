ARG FEDORA_VERSION

# add s6 overlay
# https://github.com/linuxserver/docker-baseimage-fedora/blob/master/Dockerfile
FROM alpine:latest AS rootfs-stage

RUN set -x \
  \
  && VERSION=$(wget -O - https://api.github.com/repos/just-containers/s6-overlay/releases/latest | grep tag_name | cut -d '"' -f 4) \
  && mkdir -p /root-out src \
  && wget -O src/s6-overlay-noarch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/${VERSION}/s6-overlay-noarch.tar.xz \
  && wget -O src/s6-overlay-arch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/${VERSION}/s6-overlay-$(arch).tar.xz \
  && wget -O src/s6-overlay-symlinks-noarch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/${VERSION}/s6-overlay-symlinks-noarch.tar.xz \
  && wget -O src/s6-overlay-symlinks-arch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/${VERSION}/s6-overlay-symlinks-arch.tar.xz \
  && tar -C /root-out -Jxpf src/s6-overlay-noarch.tar.xz \
  && tar -C /root-out -Jxpf src/s6-overlay-arch.tar.xz \
  && tar -C /root-out -Jxpf src/s6-overlay-symlinks-noarch.tar.xz \
  && tar -C /root-out -Jxpf src/s6-overlay-symlinks-arch.tar.xz \
  && rm -rf src

## main build

ARG FEDORA_VERSION
FROM registry.fedoraproject.org/fedora:$FEDORA_VERSION

COPY --from=rootfs-stage /root-out/ /

RUN set -x \
  \
  && echo 'exclude=*.i386 *.i686' >> /etc/dnf.conf \
  && dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
  && dnf copr enable -y \
    lizardbyte/beta \
  && dnf install -y --setopt=install_weak_deps=False --best \
    # tools
    tini \
    sudo \
    git-core \
    iproute-tc \
    iptables-nft \
    iputils \
    gzip \
    tar \
    xz \
    unar \
    jq \
    procps-ng \
    which \
    lsof \
    strace \
    ldns-utils \
    vim-minimal \
    tmux \
    bash-completion \
    gawk \
    cvt \
    \
    mesa-dri-drivers \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    mesa-vulkan-drivers \
    libva-nvidia-driver \
    vulkan \
    vulkan-tools \
    pulseaudio \
    pulseaudio-utils \
    glx-utils \
    glibc-all-langpacks \
    systemd-udev \
    default-fonts-cjk-mono \
    default-fonts-cjk-sans \
    default-fonts-cjk-serif \
    default-fonts-core-emoji \
    default-fonts-core-math \
    default-fonts-core-mono \
    default-fonts-core-sans \
    default-fonts-core-serif \
    default-fonts-other-mono \
    default-fonts-other-sans \
    default-fonts-other-serif \
    # Sway
    seatd \
    sway \
    foot \
    # apps
    Sunshine \
    steam \
    gamescope \
    wlr-randr \
    xorg-x11-drv-libinput \
  \
  && dnf clean all \
  && rm -rf \
    /var/cache \
    /var/log/* \
  && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel

COPY /root /

ENV \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
  S6_VERBOSITY=1 \
  LANG=C.UTF-8 \
  SUNSHINE_PORT=47989 \
  COLOR_DEPTH=24 \
  DESKTOP_SESSION=sway \
  XDG_CURRENT_DESKTOP=sway \
  XDG_DATA_DIRS=/usr/local/share:/usr/share \
  XDG_SESSION_DESKTOP=sway \
  XDG_SESSION_TYPE=wayland \
  WLR_BACKENDS=headless,libinput \
  WLR_LIBINPUT_NO_DEVICES=1 \
  LIBSEAT_BACKEND=seatd

# ENV \
#   USER=sunshine \
#   UID=10000 \
#   HOME=/home/sunshine \
#   XDG_RUNTIME_DIR=/run/user/10000 \
#   SUNSHINE_USERNAME=sunshine \
#   SUNSHINE_PASSWORD=password

ENTRYPOINT ["/init"]