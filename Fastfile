require "json"

APP_IDENTIFIER = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
PACKAGE_NAME   = CredentialsManager::AppfileConfig.try_fetch_value(:package_name)

# ── S3 ──────────────────────────────────────────────────────────────────────

def s3_client
  require "aws-sdk-s3"

  @s3_client ||= Aws::S3::Client.new(
    region: ENV.fetch("S3_REGION", "auto"),
    endpoint: ENV["S3_ENDPOINT"],
    access_key_id: ENV["S3_ACCESS_KEY_ID"],
    secret_access_key: ENV["S3_SECRET_ACCESS_KEY"],
    force_path_style: true,
  )
end

def upload_to_s3(file:, key:, content_type: "application/octet-stream")
  s3_client.put_object(
    bucket: ENV["S3_BUCKET"],
    key: key,
    body: File.open(file),
    content_type: content_type,
  )
  "#{ENV['S3_PUBLIC_URL']}/#{key}"
end

def s3_install_url(ipa:, app_id: APP_IDENTIFIER)
  slug = app_id.split(".").last

  ipa_url = upload_to_s3(file: ipa, key: "#{slug}/app.ipa")

  manifest = {
    "items" => [{
      "assets"   => [{ "kind" => "software-package", "url" => ipa_url }],
      "metadata" => {
        "bundle-identifier" => app_id,
        "bundle-version"    => "1.0",
        "kind"              => "software",
        "title"             => app_id,
      },
    }],
  }.to_plist
  manifest_path = File.join(Dir.tmpdir, "manifest.plist")
  File.write(manifest_path, manifest)
  manifest_url = upload_to_s3(file: manifest_path, key: "#{slug}/manifest.plist", content_type: "application/xml")

  install_url = "itms-services://?action=download-manifest&url=#{manifest_url}"
  redirect_path = File.join(Dir.tmpdir, "install.html")
  File.write(redirect_path, "<html><head><meta http-equiv=\"refresh\" content=\"0;url=#{install_url}\"></head></html>")
  upload_to_s3(file: redirect_path, key: "#{slug}/ios", content_type: "text/html")
end

def s3_apk_url(apk:)
  slug = PACKAGE_NAME.split(".").last
  upload_to_s3(file: apk, key: "#{slug}/android", content_type: "application/vnd.android.package-archive")
end

# ── iOS ─────────────────────────────────────────────────────────────────────

def certificate_name(match_type, app_id: APP_IDENTIFIER)
  ENV["sigh_#{app_id}_#{match_type}_certificate-name"]
end

def profile_name(match_type, app_id: APP_IDENTIFIER)
  ENV["sigh_#{app_id}_#{match_type}_profile-name"]
end

def generate_export_options(match_type, app_id: APP_IDENTIFIER)
  path = File.join(Dir.tmpdir, "ExportOptions.plist")
  File.write(path, {
    "method"               => lane_context[SharedValues::SIGH_PROFILE_TYPE],
    "signingStyle"         => "manual",
    "signingCertificate"   => certificate_name(match_type, app_id: app_id),
    "provisioningProfiles" => lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING],
  }.to_plist)
  path
end

IPA_PATH = "../../build/ios/ipa/*.ipa"

platform :ios do
  before_all do
    setup_ci
    if ENV["APP_STORE_CONNECT_API_KEY"]
      key = JSON.parse(ENV["APP_STORE_CONNECT_API_KEY"])
      app_store_connect_api_key(
        key_id: key["key_id"],
        issuer_id: key["issuer_id"],
        key_content: key["key"],
        is_key_content_base64: key["is_key_content_base64"] || false,
      )
    end
  end

  private_lane :setup_signing do |options|
    # setup_ci는 before_all에서 실행됨
    type = options[:type]
    app_id = options[:app_identifier] || APP_IDENTIFIER
    match(
      type: type,
      app_identifier: app_id,
      clone_branch_directly: true,
    )
    update_code_signing_settings(
      path: "Runner.xcodeproj",
      targets: "Runner",
      build_configurations: "Release",
      code_sign_identity: certificate_name(type, app_id: app_id),
      profile_name: profile_name(type, app_id: app_id),
    )
  end

  lane :beta do
    beta_id = "#{APP_IDENTIFIER}.beta"
    display_name = get_info_plist_value(path: "Runner/Info.plist", key: "CFBundleDisplayName")

    produce(
      app_identifier: beta_id,
      app_name: "#{display_name} Beta",
      skip_itc: true,
    )

    update_info_plist(
      xcodeproj: "Runner.xcodeproj",
      plist_path: "Runner/Info.plist",
      app_identifier: beta_id,
      display_name: "#{display_name} Beta",
    )

    type = "adhoc"
    setup_signing(type: type, app_identifier: beta_id)
    sh("flutter build ipa --export-options-plist=#{generate_export_options(type, app_id: beta_id)}")
    ipa = File.expand_path(Dir.glob(IPA_PATH).first)
    install_url = s3_install_url(ipa: ipa, app_id: beta_id)
    telegram(text: install_url)
    slack(message: install_url)
  end

  lane :release do
    type = "appstore"
    setup_signing(type: type)
    build_number = latest_testflight_build_number + 1
    sh("flutter build ipa --export-options-plist=#{generate_export_options(type)} --build-number=#{build_number}")
    deliver(
      ipa: File.expand_path(Dir.glob(IPA_PATH).first),
      app_version: YAML.load_file("../../pubspec.yaml")["version"].to_s.split("+").first,
      force: true,
      automatic_release: true,
      overwrite_screenshots: true,
      precheck_include_in_app_purchases: false,
      submit_for_review: true,
      reject_if_possible: true,
    )
    telegram(text: "✅ *#{APP_IDENTIFIER}* iOS 릴리스 배포 완료")
    slack
  end

  error do |lane, exception|
    slack(message: exception.message, success: false)
    telegram(text: "❌ *#{APP_IDENTIFIER}* iOS 배포 실패\n`#{exception.message}`")
  end
end

# ── Android ──────────────────────────────────────────────────────────────────

platform :android do
  lane :beta do
    sh("flutter build apk")
    apk = File.expand_path("../../build/app/outputs/flutter-apk/app-release.apk")
    apk_url = s3_apk_url(apk: apk)
    telegram(text: apk_url)
    slack(message: apk_url)
  end

  lane :release do
    sh("flutter build appbundle --build-number=#{google_play_track_version_codes.max + 1}")
    supply(aab: "../build/app/outputs/bundle/release/app-release.aab")
    slack
    telegram(text: "✅ *#{PACKAGE_NAME}* Android 릴리스 배포 완료")
  end

  error do |lane, exception|
    slack(message: exception.message, success: false)
    telegram(text: "❌ *#{PACKAGE_NAME}* Android 배포 실패\n`#{exception.message}`")
  end
end
