# Syncora

#### Syncora is an open source full-stack flutter project that allows users to create personal or collaborative tasks with others in real-time with offline first support.


![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

## Features

- Use the app as guest or create account using manual or google authentication
- Verify user emails and reset password
- Create, delete, edit, groups of tasks
- Invite or remove other members to groups
- Create, delete, edit tasks
- Assign multiple members to tasks for personalized work
- Notify other members in real-time when a task is completed or modified
- Offline first support, app is completely accessible when offline and syncs back seamlessly when connected

## Getting Started

#### This project depends on running [Syncora's Backend](https://github.com/Dangere/syncora-backend) either locally or by hosting it 

### Prerequisites

- Flutter SDK `>=3.x.x`
- Dart `>=3.x.x`
- Android Studio / Xcode (for device/emulator)
- [Cloudinary API](https://cloudinary.com) (for signed image upload)
- [Syncora's Backend](https://github.com/Dangere/syncora-backend)

### Installation

```bash
git clone https://github.com/Dangere/syncora-frontend.git
cd syncora-frontend
flutter pub get
```

### Environment Setup
 Update `BASE_URL` in lib/core/constants.dart to point to your backend URL. <br/>
 Update `CLOUDINARY_API_KEY` and `CLOUDINARY_UPLOAD_URL` in lib/core/image/cloudinary_image_repository.dart to point to your [Cloudinary API](https://cloudinary.com).

### Running

```bash
# Debug
flutter run

# Release
flutter run --release
```

## Built With

- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev) — State management
- [Dio](https://pub.dev/packages/dio) — HTTP client
- [Go Router](https://pub.dev/packages/go_router) — Routing
- [SQFlite](https://pub.dev/packages/sqflite) — Local database
- [Cache Manager](https://pub.dev/packages/fluter_cache_manager) — Image caching
- [SignalR](https://pub.dev/packages/signalr_netcore) — Real-time communication
- [Google Sign In](https://pub.dev/packages/google_sign_in) — Google authentication

## License

MIT
