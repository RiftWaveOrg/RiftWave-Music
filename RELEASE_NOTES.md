# RiftWave Music - Update Release Notes

We are thrilled to announce a major update to RiftWave Music! This release completely revolutionizes Music Video Mode, providing instantaneous background preloading for a flawless dual audio-video experience.

Here is everything new in this release:

## 🚀 Version 1.1.4: Seamless Music Video Mode

### 1. Dual Preload Cache
- **Instant Video Playback**: Music Video Mode is no longer a toggle that re-loads the track. The player now intelligently and silently preloads both audio and video streams in the background. Toggling the video mode now instantly reveals the flawlessly synced music video.
- **Sliding Window Preloading**: Implemented a state-of-the-art sliding window cache that always keeps the current track and the next 3 upcoming tracks fully loaded in memory for both `just_audio` and `media_kit`.

### 2. Synchronization & Performance Fixes
- **Zero-Drift Synchronization**: Improved the background sync timer with a dynamic drift tolerance. The video will stay perfectly pinned to the audio track without the "slideshow" or frame-dropping effect.
- **Instant First-Track Loading**: Refactored the dual-manifest extraction engine. When you tap a track, it extracts and starts the first track instantly, while processing the remaining queue asynchronously in the background.
