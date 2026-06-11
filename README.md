# NVR-Display

NVR-Display is a lightweight, script-based digital signage and network video recorder (NVR) display tool designed specifically for Alpine Linux. It utilizes `ffmpeg` to render a background image, timelapse, or video stream directly to the local framebuffer (`/dev/fb0`), overlaying it with dynamically updating information such as the date, time, device IP address, temperature, and weather forecast.

## Features
* **Framebuffer Rendering:** Outputs directly to `/dev/fb0` using `ffmpeg`, making it incredibly resource-efficient and perfect for minimal Alpine Linux installations (like a Raspberry Pi).
* **Live Overlays:** Displays the system's IP address, current date and time (12h/24h formats), local temperature, and weather forecast text.
* **Timelapse Downloader:** Automatically pulls updated background images (e.g., from an IP camera or NVR) at configurable intervals.
* **Modular Services:** Managed via OpenRC init scripts, separating the downloader, forecast fetcher, and main display engine into distinct background services using `screen`.
* **Unified Configuration:** Easily customizable via a single configuration file.

## Requirements
* **OS:** Alpine Linux (utilizes OpenRC init system and `ash` shell).
* **Dependencies:** `ffmpeg`, `screen`, `wget`, `bc`, and basic font packages (automatically handled by the installer).

## Installation & Usage

You can install, update, or remove NVR-Display using the provided `install.sh` script directly from this repository without needing to clone it manually.

### 1. Fresh Installation
To download the dependencies, set up the default configuration file, and install the services, run the following command as `root`:

```bash
wget -qO- https://raw.githubusercontent.com/gpocali/nvr-display/main/install.sh | sh

```

### 2. Updating an Existing Installation

If you want to pull the latest scripts from the repository without overwriting your current settings, use the `--update` flag. This will restart the services automatically:

```bash
wget -qO- https://raw.githubusercontent.com/gpocali/nvr-display/main/install.sh | sh -s -- --update

```

### 3. Uninstallation

To completely stop the services, remove them from the default runlevel, and delete the scripts and configuration directory:

```bash
wget -qO- https://raw.githubusercontent.com/gpocali/nvr-display/main/install.sh | sh -s -- --uninstall

```

## Configuration

After installation, the system is controlled via a single configuration file located at:
`/etc/nvr-display/nvr-display.conf`

Here, you can modify:

* **Background Source:** Set the URL for your IP camera or timelapse image.
* **Refresh Intervals:** Control how often the downloader fetches new images.
* **Weather & Forecast APIs:** Define the endpoints used to grab the current temperature and forecast string.
* **Visuals & Positioning:** Enable or disable specific overlays (time, date) and adjust their X/Y coordinates, fonts, colors, and bounding boxes.

Once you make changes to the configuration file, restart the display service to apply them:

```bash
rc-service nvr-display restart

```

## Services Overview

The installation configures three OpenRC services to run on boot:

* `nvr-display`: The main `ffmpeg` loop that composites the final image and pushes it to the display.
* `nvr-downloader`: A background loop that continuously fetches the background/timelapse image.
* `nvr-forecast`: A background loop that updates `/tmp/forecast` and `/tmp/temperature` every 60 seconds.

You can check their status using:

```bash
rc-status

```

## License

This project is licensed under the [GNU General Public License v3.0 (GPLv3)](https://www.google.com/search?q=LICENSE).
