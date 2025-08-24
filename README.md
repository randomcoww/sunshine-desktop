### Container for Steam over Sunshine

Originally based on https://github.com/Steam-Headless/docker-steam-headless/tree/master but has changed quite a bit now.

Currently migrating to Wayland and isn't able to fully use the Nvidia GPU. Nvidia graphics acceleration works in applications like games, but desktop rendering and Sunshine encoding seems to only work on an alternate GPU with non proprietary drivers.

My environment is also a little unique and some common modules like `nvidia-drm` are currently not installed with the driver, so this may be the issue.

Latest Sunshine release

```bash
curl -s https://api.github.com/repos/LizardByte/Sunshine/tags | grep name | head -1 | cut -d '"' -f 4 | tr -d 'v'
```