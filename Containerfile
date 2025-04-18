ARG FEDORA_VERSION=39

# add s6 overlay
# https://github.com/linuxserver/docker-baseimage-fedora/blob/master/Dockerfile
FROM alpine:edge AS rootfs-stage

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

## build sunshine for fedora

FROM registry.fedoraproject.org/fedora:$FEDORA_VERSION AS sunshine
ARG VERSION

RUN set -x \
  \
  && dnf install -y --setopt=install_weak_deps=False \
    git-core \
    jq \
  \
  # && VERSION=$(curl -s https://api.github.com/repos/LizardByte/Sunshine/tags | jq -r '.[0].name' | tr -d 'v') \
  && git clone --depth 1 -b v$VERSION \
    --recurse-submodules https://github.com/LizardByte/Sunshine.git /sunshine \
  && cd /sunshine \
  && chmod +x ./scripts/linux_build.sh \
  && ./scripts/linux_build.sh \
    --publisher-name='LizardByte' \
    --publisher-website='https://app.lizardbyte.dev' \
    --publisher-issue-url='https://app.lizardbyte.dev/support' \
    --sudo-off

## main build

FROM registry.fedoraproject.org/fedora-minimal:$FEDORA_VERSION

COPY --from=rootfs-stage /root-out/ /
COPY --from=sunshine /sunshine/build/cpack_artifacts/Sunshine.rpm /

RUN set -x \
  \
  && echo 'exclude=*.i386 *.i686' >> /etc/dnf.conf \
  && microdnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
  \
  && microdnf install -y --setopt=install_weak_deps=False --best \
    # tools
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
    xrandr \
    xdpyinfo \
    glibc-all-langpacks \
    systemd-udev \
    # f39 fonts
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
    # xfce4-pulseaudio-plugin \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    xfdesktop \
    xfwm4 \
    # apps
    /Sunshine.rpm \
    flatpak \
  \
  && microdnf clean all \
  && rm -rf \
    /var/cache \
    /var/log/* \
    /Sunshine.rpm

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
  NVIDIA_DRIVER_BASE_URL=https://us.download.nvidia.com/tesla \
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