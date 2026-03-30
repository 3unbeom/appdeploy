# Flutter Deploy

A GitHub Action to build and deploy Flutter apps via Fastlane.

## Usage

```yaml
- uses: 3unbeom/flutter-deploy@main
  with:
    platform: all
    lane: release
  env:
    DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
    DOPPLER_PROJECT: your-project
    DOPPLER_CONFIG: your-config
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `platform` | Target platform. `android`, `ios`, `all` | `all` |
| `lane` | Deploy type. `release`, `beta` | `release` |

## Appfile

```sh
mkdir -p android/fastlane ios/fastlane
echo 'package_name "com.example.app"' > android/fastlane/Appfile
echo 'app_identifier "com.example.app"' > ios/fastlane/Appfile
```

## GitHub Secrets

| Name | Description |
|------|-------------|
| `DOPPLER_TOKEN` | Doppler service token |

## Environment Variables

### iOS

| Name | Description |
|------|-------------|
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API key |
| `MATCH_GIT_URL` | match certificate repository URL |
| `MATCH_KEYCHAIN_PASSWORD` | match keychain password |
| `MATCH_PASSWORD` | match certificate encryption password |

### Android

| Name | Description |
|------|-------------|
| `SUPPLY_JSON_KEY_DATA` | Google Play service account JSON |

### Cloudflare R2 (iOS beta)

| Name | Description |
|------|-------------|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | R2 S3 API access key ID |
| `R2_SECRET_ACCESS_KEY` | R2 S3 API secret access key |
| `R2_BUCKET` | R2 bucket name |
| `R2_PUBLIC_URL` | R2 public URL (custom domain or r2.dev) |

### Slack

| Name | Description |
|------|-------------|
| `SLACK_URL` | Slack webhook URL |

### Telegram

| Name | Description |
|------|-------------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token |
| `TELEGRAM_CHAT_ID` | Telegram chat ID to receive notifications |
