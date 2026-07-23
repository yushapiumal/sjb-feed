# Statelink

Flutter application for Statelink.

## Getting Started

This project is a Flutter application configured for cross-platform deployment (iOS, Android, Web).

### Prerequisites
- Flutter SDK (stable channel)
- CocoaPods (`pod install` for iOS)

---

## Codemagic CI/CD (iOS Build Guide)

This repository includes a pre-configured [`codemagic.yaml`](file:///home/akesh/Work/statelink/codemagic.yaml) file supporting both signed and unsigned iOS builds.

### 1. Workflows Available
- **`ios-release`**: Generates a signed release `.ipa` file using App Store Connect automatic code signing.
- **`ios-unsigned`**: Builds an unsigned `.ipa` / `.app` package suitable for quick CI build verification without needing Apple credentials.

### 2. Setting Up Codemagic UI

1. **Sign in & Import Repository**:
   - Log into [Codemagic.io](https://codemagic.io/).
   - Connect your Git repository provider and add the **Statelink** project.

2. **Configure Environment Variables (For Signed Builds)**:
   - Go to **Teams / Apps** -> **Environment variables** in Codemagic.
   - Create a Variable Group named `app_store_credentials` with the following variables:
     - `APP_STORE_CONNECT_ISSUER_ID`: Found in App Store Connect -> Users and Access -> Integrations -> Keys.
     - `APP_STORE_CONNECT_KEY_IDENTIFIER`: Key ID of your App Store Connect API Key.
     - `APP_STORE_CONNECT_PRIVATE_KEY`: Content of the `.p8` API key file.
     - `CERTIFICATE_PRIVATE_KEY`: Private key for your iOS Distribution Certificate (RSA 2048-bit private key).

3. **Triggering Builds**:
   - Push to `main` or `master` to automatically trigger a signed release build (`ios-release`).
   - Create a Pull Request to trigger an unsigned verification build (`ios-unsigned`).
   - Alternatively, start a build manually from the Codemagic Dashboard UI by selecting your workflow (`ios-release` or `ios-unsigned`).

4. **Artifacts**:
   - Successful builds output the `.ipa` package under `Artifacts` in the Codemagic build summary page.

