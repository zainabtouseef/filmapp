# CineConnect icon assets

The master artwork is `cineconnect_app_icon.svg`. Run `python3 tools/generate_app_icons.py` from the repository to regenerate the platform icons. The generator requires `rsvg-convert` and Pillow.

- `CineConnect-AppStore-1024.png`: 1024 × 1024 opaque PNG for the iOS App Store icon.
- `CineConnect-PlayStore-512.png`: 512 × 512, 32-bit RGBA PNG for the Google Play listing.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset`: all iOS app icon sizes used by Xcode.
- `android/app/src/main/res/mipmap-*`: Android launcher and adaptive icon images.
- `web/favicon.png`, `web/favicon.ico`, `web/apple-touch-icon.png`, and `web/icons`: browser and installable web app icons.

The images and platform references are set in the project. Store submission still requires a release build, app identifiers, signing, and store listing details.
