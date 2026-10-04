# Shopping App – Admin Panel

A separate Flutter app for the shop owner. It is **not** part of the shopping app, but it
uses the same Firebase project (`shopapp-68db3`), so everything you do here shows up in the
shopping app right away.

## What you can do

- **Dashboard** – revenue, orders, pending orders, products, users, latest orders
- **Orders** – every order arrives live (pop-up + red badge on *Orders*), filter by status,
  search, change status (Pending → On the way! → Delivered / Cancelled), delete
- **Products** – add, edit, delete; name, category, price, discount %, details, picture
  (upload from the computer, built-in picture, or a picture link).
  *Import built-in products* copies the app's 11 starter products so you can edit them.
- **Users** – everyone who signed up in the shopping app

## Run it

Open a terminal in this folder (`E:\shoppingapp\admin_panel`):

```
flutter pub get
flutter run -d chrome      # in the Chrome browser (works now)
flutter run                # on a connected Android phone / emulator
flutter run -d windows     # as a Windows app (needs Visual Studio, see below)
```

In **Android Studio**: *File → Open* → choose the `admin_panel` folder (not the shopping
app folder), pick a device (phone, emulator or Chrome) in the device list and press Run.

### Install on a phone

`flutter build apk --release` → copy `build\app\outputs\flutter-apk\app-release.apk` to the
phone and open it (allow "install unknown apps"). The app is called **Shop Admin**.
On phones the menu is at the bottom; on computers it is on the left.

### Windows app setup (one time)

1. Install **Visual Studio 2022 Community** (free) from https://visualstudio.microsoft.com/downloads/
2. In the installer tick the **"Desktop development with C++"** workload and install.
3. Run `flutter doctor` – the *Visual Studio* line should be green.
4. `flutter run -d windows` (the first build downloads the Firebase C++ SDK and takes a while).
5. To get a stand-alone program: `flutter build windows` →
   `build\windows\x64\runner\Release\admin_panel.exe` (copy the whole `Release` folder).

## First login

Only **saruarhossain778620@gmail.com** can use the panel (set in `lib/config.dart` and in
`firestore.rules` in the shopping app folder – change both together).

1. Type a password and click **Create owner account** (first time only).
2. Open the verification email (check Spam), click the link.
3. Come back and click **Log in**.

Forgot the password? Click **Forgot password** and use the link in the email.

## Notes

- Categories must match the shopping app (`lib/config.dart` here and `lib/models/product.dart`
  in the app).
- Uploaded pictures are shrunk to 600 px and stored in Firestore (Firebase Storage needs a paid plan).
- Security rules live in `../firestore.rules`. After changing them run
  `firebase deploy --only firestore:rules` in the shopping app folder.
