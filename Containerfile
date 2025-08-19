# add s6 overlay
# https://github.com/linuxserver/docker-baseimage-fedora/blob/master/Dockerfile
FROM alpine:latest AS rootfs-stage

RUN set -x \
  \
  && VERSION=$(wget -O - https://api.github.com/repos/just-containers/s6-overlay/releases/latest | grep tag_name | cut -d '"' -f 4 | tr -d 'v') \
  && mkdir -p /root-out src \
  && wget -O src/s6-overlay-noarch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/v${VERSION}/s6-overlay-noarch.tar.xz \
  && wget -O src/s6-overlay-arch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/v${VERSION}/s6-overlay-$(arch).tar.xz \
  && wget -O src/s6-overlay-symlinks-noarch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/v${VERSION}/s6-overlay-symlinks-noarch.tar.xz \
  && wget -O src/s6-overlay-symlinks-arch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/v${VERSION}/s6-overlay-symlinks-arch.tar.xz \
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
    lizardbyte/stable \
  && dnf install -y --setopt=install_weak_deps=False --best \
    # tools
    sudo \
    git-core \
    git-lfs \
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
    dbus-x11 \
    xorg-x11-server-Xorg \
    xorg-x11-drv-evdev \
    xrandr \
    xdpyinfo \
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
    # XFCE
    gtk-xfce-engine \
    xfce4-appfinder \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    xfdesktop \
    xfwm4 \
    # apps
    Sunshine-$VERSION \
    flatpak \
  \
  && dnf clean all \
  && rm -rf \
    /var/cache \
    /var/log/*

RUN set -x \
  \
  && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel \
  && rm -f \
    /etc/xdg/autostart/xfce-polkit.desktop \
    /etc/xdg/autostart/at-spi-dbus-bus.desktop \
    /usr/share/applications/xfce4-accessibility-settings.desktop \
    /usr/share/applications/xfce4-color-settings.desktop \
    /usr/share/applications/xfce4-mail-reader.desktop \
    /usr/share/applications/xfce4-session-logout.desktop \
    /usr/share/applications/xfce-ui-settings.desktop \
    /usr/share/applications/xfce4-web-browser.desktop \
    /usr/share/applications/thunar-bulk-rename.desktop

COPY /root /

ENV \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
  S6_VERBOSITY=1 \
  LANG=C.UTF-8 \
  SUNSHINE_PORT=47989 \
  DISPLAY_DEVICE=DFP \
  DISPLAY=:16 \
  COLOR_DEPTH=24

# ENV \
#   USER=sunshine \
#   UID=10000 \
#   HOME=/home/sunshine \
#   XDG_RUNTIME_DIR=/run/user/10000 \
#   SUNSHINE_USERNAME=sunshine \
#   SUNSHINE_PASSWORD=password

ENTRYPOINT ["/init"]