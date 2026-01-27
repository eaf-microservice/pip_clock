# Pip O'Clock

**Pip O'Clock** is a Flutter application that plays a "pip" sound (or custom alarm) exactly on the hour, every hour. It is designed to work reliably in the background on both Android and iOS.

<!--
███████╗ ██████╗ ██╗   ██╗ █████╗ ██████╗     ███████╗ █████╗ ███████╗
██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔══██╗    ██╔════╝██╔══██╗██╔════╝
█████╗  ██║   ██║██║   ██║███████║██║  ██║    █████╗  ███████║█████╗
██╔══╝  ██║   ██║██║   ██║██╔══██║██║  ██║    ██╔══╝  ██╔══██║██╔══╝
██║     ╚██████╔╝╚██████╔╝██║  ██║██████╔╝    ███████╗██║  ██║██║
╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚══════╝╚═╝  ╚═╝╚═╝
-->

## Features

- **Hourly Chime**: Plays a sound at HH:00:00.
- **Background Support**:
  - **Android**: Uses a high-priority Foreground Service to ensure exact timing and changing the notification ticker.
  - **iOS**: Uses Scheduled Local Notifications to ensure reliability when the app is in the background or closed.
- **Customizable**: Toggle the alarm on/off within settings.
- **Visual Clock**: Simple, large digital clock display with seconds.

## Getting Started

### Prerequisites

- Flutter SDK (3.5.3 or later)
- Android Studio / Xcode

### Installation

1.  **Clone the repository**:

    ```bash
    git clone https://github.com/yourusername/pip_clock.git
    cd pip_clock
    ```

2.  **Install dependencies**:

    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

## Build & Signing

### Android

To build a release APK/Bundle, you need a keystore.

1.  Create a `key.properties` file in the `android/` directory (this file is git-ignored):
    ```properties
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=YOUR_KEY_ALIAS
    storeFile=../upload-keystore.jks
    ```
2.  Place your `upload-keystore.jks` in the `android/` folder (or adjust the path in `key.properties`).
3.  Build:
    ```bash
    flutter build apk --release
    ```

## Permissions

### Android

- **Notifications**: Required to show the persistent "Pip Clock Service" notification.
- **Ignore Battery Optimizations**: Requested to ensure the timer isn't killed by the OS (on some devices).

### iOS

- **Notifications**: Required to deliver the hourly sound when the app is backgrounded.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.
