<div align="center">

<img src="assets/images/RiftWave_Card.png" width="100%" alt="RiftWave Music Banner">

# RiftWave Music
**An open-source, beautifully designed, and highly optimized music streaming app.**  
*No ads. No tracking. No accounts. Just pure music.*

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-blue?logo=flutter&logoColor=white)](https://flutter.dev)
[![GitHub Release](https://img.shields.io/github/v/release/Pratyush0803/RiftWave-Music?color=success&label=Latest%20Release&logo=github)](https://github.com/Pratyush0803/RiftWave-Music/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Pratyush0803/RiftWave-Music?style=social)](https://github.com/Pratyush0803/RiftWave-Music/stargazers)

[**Download**](#-download) • [**Features**](#-features) • [**Screenshots**](#-screenshots) • [**FAQ**](#-faq) • [**Legal Disclaimer**](#-legal-disclaimer--terms-of-use)

</div>

---

## 🎵 About

**RiftWave Music** is a sleek, completely free, and open-source music streaming application built using Flutter. It aims to provide a premium music streaming experience without the clutter of ads, the intrusion of trackers, or the friction of account sign-ups.

Powered by robust APIs behind the scenes (such as YouTube and JioSaavn), RiftWave delivers high-quality audio, synced lyrics, and native music video playback directly to your device.

---

## ✨ Features

- 🚫 **Ad-Free Experience:** Uninterrupted listening, forever.
- 🎨 **Material You & Dynamic Theming:** Beautiful UI that adapts to your device's wallpaper, featuring True Black (AMOLED) and sleek dark modes.
- 📥 **Offline Downloads:** Cache and download your favorite tracks directly to your local storage using our custom high-speed chunked downloader.
- 🎬 **Music Video Mode:** Watch HD music videos natively integrated directly within the player.
- 📝 **Live Synced Lyrics:** Follow along with your favorite songs using real-time synchronized lyrics (powered by LRCLIB).
- 🔁 **Gapless Playback:** Seamless transition between tracks for the perfect album listening experience.
- 📱 **Cross-Platform Support:** Available for Android, Windows, Linux, and macOS.
- 🔒 **Privacy First:** Your data stays on your device. No telemetry, no usage tracking, no cloud accounts.
- 📻 **Smart Recommendations:** Auto-play similar tracks to keep the music going based on your listening history.
- 🎛️ **System Integration:** Lock-screen controls, background playback, and media session support.

---

## 📸 Screenshots

Here is a glimpse into the beautiful design and experience of RiftWave Music:

<p align="center">
  <img src="assets/riftwave_image/0.jpg" width="32%">
  <img src="assets/riftwave_image/1.jpg" width="32%">
  <img src="assets/riftwave_image/2.jpg" width="32%">
</p>
<p align="center">
  <img src="assets/riftwave_image/3.jpg" width="32%">
  <img src="assets/riftwave_image/4.jpg" width="32%">
  <img src="assets/riftwave_image/5.jpg" width="32%">
</p>

<details>
<summary><b>🔥 Click to view more screenshots</b></summary>
<br>

<p align="center">
  <img src="assets/riftwave_image/6.jpg" width="32%">
  <img src="assets/riftwave_image/7.jpg" width="32%">
  <img src="assets/riftwave_image/8.jpg" width="32%">
</p>
<p align="center">
  <img src="assets/riftwave_image/9.jpg" width="32%">
  <img src="assets/riftwave_image/10.jpg" width="32%">
  <img src="assets/riftwave_image/11.jpg" width="32%">
</p>
<p align="center">
  <img src="assets/riftwave_image/12.jpg" width="32%">
  <img src="assets/riftwave_image/13.jpg" width="32%">
  <img src="assets/riftwave_image/14.jpg" width="32%">
</p>
<p align="center">
  <img src="assets/riftwave_image/15.jpg" width="32%">
  <img src="assets/riftwave_image/16.jpg" width="32%">
  <img src="assets/riftwave_image/17.jpg" width="32%">
</p>

</details>

---

## 📥 Download

Grab the latest version of RiftWave Music!

<p align="left">
  <a href="https://github.com/Pratyush0803/RiftWave-Music/releases">
    <img src="https://img.shields.io/badge/Get_it_on-GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="Get it on GitHub" height="50">
  </a>
</p>

- **Android:** Download the `.apk` file (`RiftWave-Android-arm64.apk` recommended for most modern phones).
- **Windows:** Download the `RiftWave-Windows.zip` file, extract it, and run the `.exe` inside.
- **Linux:** Download the `RiftWave-Linux.tar.gz` bundle.
- **macOS:** Download the `RiftWave-macOS.zip` bundle.

---

## 🛠 Installation (Android)

1. Go to the [Releases](https://github.com/Pratyush0803/RiftWave-Music/releases) page.
2. Download the appropriate `.apk` file for your device's architecture.
3. Open the downloaded file. You may be prompted to allow **"Install from unknown sources"**.
4. Enable the permission, complete the installation, and enjoy the music!

---

## ❓ FAQ

#### 1. Why are some lyrics missing or slightly out of sync?
Lyrics are provided primarily by **LRCLIB**. Since they rely on community submissions and string matching using the track's duration and title, there can occasionally be mismatches if the song is a remix, a live version, or if the metadata doesn't perfectly align.

#### 2. Where is my data stored?
Everything is stored **100% locally** on your device using Hive. If you uninstall the app or clear its data, your settings, downloaded songs, and history will be deleted. We have zero access to your information.

---

## 👨‍💻 Building from Source

If you want to compile the application yourself or contribute to the development, follow these steps:

### Prerequisites
- Install [Flutter](https://flutter.dev/docs/get-started/install) (Ensure it's added to your system PATH).
- Install Android Studio (for Android builds) or Visual Studio (for Windows builds).

### Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Pratyush0803/RiftWave-Music.git
   cd RiftWave-Music
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app (Debug Mode):**
   ```bash
   flutter run
   ```
4. **Build a Release APK:**
   ```bash
   flutter build apk --release --split-per-abi
   ```

---

## 🤝 Contributing & Translation

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**. 

If you want to help translate RiftWave Music into your native language, or if you want to add new features, please fork the repository and open a Pull Request!

---

## ⚖️ Legal Disclaimer & Terms of Use

### 1. 100% Free, Open-Source & Strictly Non-Commercial
RiftWave Music is a fully open-source project created purely for educational purposes and personal use. **We do not sell this application, nor do we monetize it in any way.** There are no advertisements, no premium features, no subscriptions, and no hidden fees within the app. This project has absolutely no commercial value or financial intent.

### 2. A Custom Browser with Content Filtering
RiftWave Music acts strictly as a specialized, third-party API client. It simply parses the publicly available website content and APIs of external sources (such as YouTube and JioSaavn), rendering them in a custom user interface. The ad-free experience it provides is fundamentally no different from using a standard web browser (like Chrome or Firefox) equipped with a common ad-blocking extension (such as uBlock Origin).

### 3. Support Content Creators
We deeply respect the hard work of artists, musicians, and content creators. **We strongly encourage all users to subscribe to official premium services (such as YouTube Premium or Spotify Premium).** Purchasing a Premium subscription is the best way to financially support the creators you listen to and ensure the continued growth of the platform. RiftWave Music is built as an educational proof-of-concept for developers and enthusiasts, not to harm creators' revenues.

### 4. No Hosting of Copyrighted Material
We do not host, upload, distribute, or store any audio, video, or copyrighted media files on our own servers. All content accessed through this application is stored entirely on the respective platform's servers and remains the property of their respective copyright owners. The app merely acts as a conduit to stream publicly accessible links.

### 5. User Responsibility & Legal Contact
The software is provided "AS IS", without warranty of any kind. The developers of RiftWave Music do not encourage or condone piracy. Users are solely responsible for ensuring their usage of this app complies with their local copyright laws and the Terms of Service of the platforms they access. 

Because we do not host any media files, we cannot process DMCA takedown requests for audio or video content. However, if you represent a copyright holder or have legal concerns regarding the open-source code itself, please open an issue or contact the repository owner.

---

## 📄 License

Distributed under the GPL-3.0 License. See `LICENSE` for more information.

<br>
<p align="center">
  Made with ❤️ by <a href="https://github.com/Pratyush0803">Pratyush Kumar Jena</a>
</p>
