# RiftWave Music - Update Release Notes

We are thrilled to announce a major update to RiftWave Music! This release focuses on completely revamping the YouTube login experience, massively improving audio streaming reliability, polishing the app's visual identity, and anonymizing user data. 

Here is everything new in this release:

## 🚀 Major Features & Enhancements

### 1. Completely Revamped YouTube Login System
- **Secure Google Sign-In**: We completely redesigned the YouTube Login architecture to match industry standards (inspired by SimpMusic). You will no longer encounter Google's frustrating "Not secure browser" error when trying to log in.
- **New Account Management UI**: Added a gorgeous, sleek bottom-sheet dialog accessible from the Settings menu to manage your connected YouTube account.
- **Privacy-First Design**: The UI has been carefully anonymized. It elegantly displays your YouTube Avatar and a clean "YouTube Account" / "Signed in" status while keeping your real Google Account name and handle hidden from the UI for your privacy (perfect for screen recording or screenshots).

### 2. Audio Engine Reliability
- **Zero-Skip YouTube Streaming**: Fixed a critical bug where YouTube would block audio streams with a `403 Forbidden` error when switching songs or restarting the app. The `just_audio` background handler now explicitly spoofs a Windows Desktop User-Agent instead of using ExoPlayer's default, ensuring uninterrupted playback across your entire playlist.

### 3. Visual Identity & Theming
- **Brand New App Icon**: RiftWave Music now sports a gorgeous, custom-designed App Icon. We generated multiple iterations and applied the selected premium icon seamlessly across all platforms (Android, iOS, macOS, Windows, and Web).
- **Amoled Dark Mode**: Polished the app's dark theme colors for a deeper, richer AMOLED experience.

### 4. Codebase Optimization
- **Production Ready**: Executed a comprehensive codebase cleanup script that stripped all redundant comments across the entire project, resulting in a cleaner, lighter codebase ready for compiling.

---

> [!TIP]
> **Developer Note**: To test the new YouTube Login, navigate to Settings > YouTube Account. If you previously had issues streaming, try skipping through multiple YouTube tracks—the new User-Agent fix ensures playback will be buttery smooth!
