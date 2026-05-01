# Building Signed Android App Bundle (.aab) for Play Store

## Prerequisites
1. **Android Studio** installed
2. **Flutter SDK** set up
3. **JDK 11 or higher** installed
4. Your app code ready and tested

---

## Step 1: Generate Signing Key

### Create a Keystore (One-time setup)
```bash
keytool -genkey -v -keystore ~/snakes-ladders-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias snakes-ladders-key
```

**Important Information to Remember:**
- **Keystore Password**: [Choose a strong password]
- **Key Alias**: snakes-ladders-key
- **Key Password**: [Choose a strong password]
- **Store the .jks file safely** - you'll need it for all future updates!

---

## Step 2: Configure App Signing

### Create `android/key.properties` file:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=snakes-ladders-key
storeFile=../snakes-ladders-key.jks
```

### Update `android/app/build.gradle`:
Add this BEFORE the `android` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside the `android` block, replace the `buildTypes` section:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## Step 3: Update App Configuration

### In `android/app/build.gradle`, ensure these values:
```gradle
android {
    namespace 'com.yourcompany.snakesladders'
    compileSdk 34
    
    defaultConfig {
        applicationId 'com.yourcompany.snakesladders'
        minSdkVersion 23
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }
}
```

### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.snakesladders">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:label="Snakes &amp; Ladders"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-9159991034200271~2215479346"/>
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## Step 4: Add App Icons

Replace the default icons in:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72×72)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48×48)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96×96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144×144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192×192)

**Quick Icon Generation Tool**: 
Use Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/

---

## Step 5: Build the App Bundle

### Clean and Get Dependencies
```bash
flutter clean
flutter pub get
```

### Build Release AAB
```bash
flutter build appbundle --release
```

### Verify Build Success
If successful, you'll find your `.aab` file at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Step 6: Test Your AAB (Optional but Recommended)

### Install AAB locally for testing:
```bash
# Install bundletool
brew install bundletool  # macOS
# or download from: https://github.com/google/bundletool

# Generate APKs from AAB
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks --ks=snakes-ladders-key.jks --ks-pass=pass:YOUR_KEYSTORE_PASSWORD --ks-key-alias=snakes-ladders-key --key-pass=pass:YOUR_KEY_PASSWORD

# Install on connected device
bundletool install-apks --apks=app.apks
```

---

## Step 7: Upload to Google Play Console

1. **Go to Google Play Console**: https://play.google.com/console
2. **Create New App** or select existing app
3. **Upload your .aab file** in the "Production" track
4. **Fill in Store Listing** with the content provided above
5. **Add screenshots** (you'll need 2-8 screenshots)
6. **Set Content Rating** (Everyone or Everyone 10+)
7. **Submit for Review**

---

## Important Files Checklist

Before uploading, ensure you have:
- ✅ `app-release.aab` file (signed)
- ✅ App icon (multiple sizes)
- ✅ Feature graphic (1024×500)
- ✅ Screenshots (2-8 images)
- ✅ Privacy policy URL
- ✅ App description and metadata
- ✅ Content rating completed

---

## Troubleshooting

### Common Issues:
1. **Signing Issues**: Ensure key.properties path is correct
2. **AdMob Errors**: Verify App ID in AndroidManifest.xml
3. **Build Failures**: Run `flutter doctor` to check setup
4. **Upload Errors**: Ensure unique applicationId and increment versionCode

### Build Commands Summary:
```bash
# Full build sequence
flutter clean
flutter pub get  
flutter pub upgrade
flutter build appbundle --release --verbose
```

---

## Security Reminders

🔒 **Keep Safe:**
- Store your `.jks` keystore file securely
- Backup your keystore and passwords
- Never share your signing key
- Use the same signing key for all app updates

Your `.aab` file is now ready for Google Play Store upload! 🚀