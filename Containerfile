ARG FEDORA_VERSION
FROM registry.fedoraproject.org/fedora:$FEDORA_VERSION

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

COPY sunshine-prep-cmd.sh /usr/local/bin/

ENV \
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

ENTRYPOINT ["tini", "--"]