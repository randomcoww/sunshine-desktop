### Container for Sunshine with integrated XFCE desktop

Based on https://github.com/Steam-Headless/docker-steam-headless/tree/master

Notable differences include

- No Steam or browser by default. They can be added as user flatpaks.
- No VNC. Sunshine only for remote access.
- Requires Nvidia GPU. Setup breaks unless `nvidia-smi` can run.
- Built on Fedora 39 (Sunshine CUDA build only supports up to F39).
- Runs on S6-overlay init.
- Intended to work in Kubernetes with configMap mounts to support service configuration.
