# Flutter GoSecure Migration Progress - Current Session

## ✅ **Completed Milestones**

### 1. **Android Gradle Namespace Issue - RESOLVED**
- **Problem**: Android Gradle Plugin (AGP) 8.0+ requires `namespace` in library modules
- **Error**: "Namespace not specified" for `:call_log`, `:flutter_inappwebview`, `:sound_mode`, `:telephony`, etc.
- **Solution Implemented**:
  - Created `android/plugin-namespace-fix.gradle` script
  - Applied via `android/settings.gradle`
  - Automatically assigns fallback namespaces to plugins missing them
  - All library plugins now properly configured

### 2. **Dependencies Resolution - PARTIAL**
- ✅ Removed conflicting `sim_data` package
- ✅ Downgraded `sensors_plus` from ^4.0.2 → ^1.4.1 (required by `shake` plugin)
- ✅ Upgraded `package_info_plus` to ^9.0.0 (web compatibility)
- ✅ Pinned `flutter_tts` to 4.0.2 (plugin manifest compatibility)
- ✅ Bumped `call_log` to ^6.0.1 (AGP namespace support)
- ✅ **Removed `motion_sensors` 0.1.0** (outdated, incompatible Kotlin)
- ✅ Updated Android SDK targets: `compileSdk 36`, `targetSdk 36`
- ⚠️ Gradle build now progresses to Dart compilation phase

### 3. **Android Configuration Updates**
- ✅ Updated `android/app/build.gradle`:
  - Changed `compileSdkVersion 35` → `36`
  - Changed `targetSdkVersion 35` → `36`
  - Kotlin target JVM: `21`
- ✅ Plugin namespace Gradle hook working successfully

---

## 🔴 **Current Blockers - Dart Compilation Errors**

Build is now failing at Dart compilation with numerous errors. Main issues:

### A. **Missing Plugin Dependencies**
1. **`motion_sensors` Removed** (was outdated):
   - `lib/HiddenCamera/detection.dart` still imports and uses it
   - References: `GyroscopeEvent`, `AccelerometerEvent`, `UserAccelerometerEvent`, `MagnetometerEvent`, `OrientationEvent`, `AbsoluteOrientationEvent`, `ScreenOrientationEvent`
   - **Fix**: Replace with `sensors_plus` stream events (accelerometerEvents, gyroscopeEvents, etc.)

2. **Missing `flutter_spinkit`** (for loading animations):
   - `lib/Dashboard/DashWidgets/Scream.dart` uses `SpinKitDoubleBounce`
   - `lib/Dashboard/DashWidgets/SafeHome.dart` uses `SpinKitDoubleBounce`
   - **Fix**: Add `flutter_spinkit: ^5.2.1` to `pubspec.yaml`

3. **Missing `carousel_slider` Update**:
   - `lib/Dashboard/Articles - SafeCarousel/SafeCarousel.dart` uses old API
   - `CarouselOptions` API changed in newer versions
   - **Fix**: Add to pubspec.yaml and update API calls

4. **Missing `flutter_slidable` for old API**:
   - `lib/Dashboard/ContactScreens/MyContacts.dart` uses `Slidable`, `SlidableDrawerActionPane`, `IconSlideAction`
   - These classes were renamed/removed in newer versions
   - **Fix**: Either pin old version or migrate to new `Slidable` API

5. **Missing `flutter_glow` or `avatar_glow`**:
   - `lib/Dashboard/Home.dart` uses `AvatarGlow`
   - **Fix**: Add `avatar_glow: ^2.1.0` or use `flutter_glow`

6. **Missing `Pinput` widget**:
   - `lib/Dashboard/Settings/ChangePin.dart` uses `Pinput`
   - **Fix**: Add `pinput: ^5.0.0` to dependencies

7. **`Blurry` Widget API Changed**:
   - `lib/Dashboard/Home.dart` uses `Blurry()` without required `themeColor` parameter
   - **Fix**: Update call or upgrade to compatible version

### B. **Null-Safety and Type Errors**
1. **Phone Contact List Issues** (`phonebook_view.dart`):
   - `_items` uninitialized (non-nullable `List<Phone>`)
   - `.number` property access on `Object?` type
   - `snap.data[...]` on nullable `List<String>?`

2. **Animation Controller** (`AllArticles.dart`):
   - `_controller: AnimationController` uninitialized
   - Builder lambda signature mismatch with nullable child parameter

3. **Shared Preferences** (`Dashboard.dart`):
   - `prefs: SharedPreferences` field uninitialized

4. **Color API** (`AllArticles.dart`):
   - `Colors.grey[50]?.withOpacity(0.3)` - calling withOpacity on nullable Color
   - Fix: Use `.withValues()` for null-safe opacity or safe navigation

5. **Background Service API** (`SettingsScreen.dart`):
   - `isServiceRunning()` method not found (API changed)
   - `sendData()` method signature changed
   - `initialize()` is now `configure()`

### C. **Missing Widget Imports/Constructors**
- Various widget constructors changed (E.g., `_ChangePinScreenState` can't find `Pinput`)

---

## 📋 **Required Fixes (In Order)**

### **Phase 1: Add Missing Pub Packages**
```yaml
dependencies:
  flutter_spinkit: ^5.2.1         # for SpinKitDoubleBounce
  carousel_slider: ^4.2.1         # or newer, update API calls
  flutter_slidable: ^0.6.0        # or pin old version and migrate later
  avatar_glow: ^2.1.0              # for AvatarGlow widget
  pinput: ^5.0.0                   # for PIN input widget
  blurry: ^1.4.2                   # already present, may need API fix
```

### **Phase 2: Fix Dart Code Files**

#### 1. **lib/HiddenCamera/detection.dart** (High Priority)
- Remove `motion_sensors` import
- Replace with `sensors_plus` streams
- Remove custom motion sensor event types
- Update sensor listening code to use accelerometerEvents, etc.

#### 2. **lib/Dashboard/Home.dart**
- Add `AvatarGlow` import or replace with `FlutterGlow`
- Fix `Blurry` widget to pass required `themeColor` or update API

#### 3. **lib/Dashboard/Settings/SettingsScreen.dart**
- Update background service API:
  - Replace `.isServiceRunning()` with service status check
  - Replace `.sendData()` with `.invoke()`
  - Replace `.initialize()` with `.configure()`

#### 4. **lib/Dashboard/ContactScreens/MyContacts.dart**
- Fix null-safety: `snap.data?.isNotEmpty ?? false`
- Fix `Slidable` usage or update to new API
- Fix `IconSlideAction` → new API equivalent

#### 5. **lib/Dashboard/Articles - SafeCarousel/SafeCarousel.dart**
- Update `CarouselOptions` and `CarouselSlider` API if breaking changes exist

#### 6. **lib/Dashboard/DashWidgets/SafeHome.dart** & **Scream.dart**
- Add `flutter_spinkit` import
- Use `SpinKitDoubleBounce` correctly

#### 7. **lib/Dashboard/ContactScreens/phonebook_view.dart**
- Initialize `_items` with empty list
- Add null checks for contact properties
- Fix nullable list operations

#### 8. **lib/animations/bottomAnimation.dart**
- Fix builder signature to handle nullable child parameter

#### 9. **lib/Dashboard/Articles - SafeCarousel/AllArticles.dart**
- Initialize `_controller` field
- Fix nullable Color operations with safe navigation

#### 10. **lib/Dashboard/Settings/ChangePin.dart**
- Add import for `Pinput` (from `pinput` package)

---

## 🚀 **Next Steps (Recommended Action)**

### **Immediate (High Priority):**
1. Run `flutter pub get` after adding missing packages
2. Fix `detection.dart` (motion_sensors removal)
3. Fix background service API calls in SettingsScreen.dart
4. Add null-safety checks across the board

### **Then (Medium Priority):**
5. Fix widget imports and API calls
6. Test with `flutter analyze`
7. Run `flutter build apk --debug` to validate

### **Finally (Optional - Lower Priority):**
8. Migrate outdated plugin APIs (Slidable, CarouselSlider) to latest versions
9. Upgrade other plugins to newer versions (currently many have newer versions available)

---

## 📊 **Current Build Status**

| Phase | Status | Details |
|-------|--------|---------|
| Dependency Resolution | ✅ **PASS** | All packages fetched successfully |
| Android Gradle Config | ✅ **PASS** | Namespace issue resolved with plugin-namespace-fix.gradle |
| Dart Compilation | 🔴 **FAIL** | ~30+ errors: missing plugins, null-safety, API changes |
| APK Build | ⏳ **BLOCKED** | Waiting for Dart compilation to pass |

---

## 📝 **Files Modified This Session**

1. ✅ `pubspec.yaml` - dependency updates
2. ✅ `android/app/build.gradle` - SDK 35 → 36
3. ✅ `android/settings.gradle` - namespace fix hook
4. ✅ `android/plugin-namespace-fix.gradle` - **CREATED** (AGP workaround)
5. ⏳ `lib/HiddenCamera/detection.dart` - needs motion_sensors→sensors_plus migration
6. ⏳ Many other files need null-safety/API fixes

---

## 🎯 **Success Criteria**

- [ ] All Dart compilation errors resolved
- [ ] `flutter analyze` reports < 100 issues
- [ ] `flutter build apk --debug` completes successfully
- [ ] APK can be installed on device/emulator
- [ ] App launches and core features work

