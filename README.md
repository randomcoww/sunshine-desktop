### Image build

This is based on https://github.com/Steam-Headless/docker-steam-headless/tree/master

- Based on Fedora 39 (Sunshine CUDA build only supports up to F39).
- Sunshine only to access the desktop. No VNC.
- Nvidia GPUs only. Setup breaks unless `nvidia-smi` can run.
- Intended to work in Kubernetes with configMap mounts to support service configuration.

```bash
TARGETARCH=amd64
FEDORA_VERSION=39
TAG=ghcr.io/randomcoww/sunshine-desktop:$(date -u +'%Y%m%d')

podman build \
  --net host \
  --arch $TARGETARCH \
  --build-arg TARGETARCH=$TARGETARCH \
  --build-arg FEDORA_VERSION=$FEDORA_VERSION \
  -t $TAG .

podman push $TAG
```