### Container for Sunshine with integrated XFCE desktop

https://github.com/LizardByte/Sunshine

Reference: https://github.com/Steam-Headless/docker-steam-headless/tree/master

- Based on Fedora 39 (Sunshine CUDA build only supports up to F39).
- Sunshine only to access the desktop. No VNC.
- Nvidia GPUs only. Setup breaks unless `nvidia-smi` can run.
- Intended to work in Kubernetes with configMap mounts to support service configuration.

Latest version

```bash
curl -s https://api.github.com/repos/LizardByte/Sunshine/tags | jq -r '.[0].name' | tr -d 'v'
```

Tag latest by date

```bash
TAG=v$(date -u +'%Y%m%d').1
git tag -a $TAG
git push origin $TAG
```
