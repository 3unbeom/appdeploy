PUBSPEC        = YAML.load_file("../pubspec.yaml")
APP_NAME       = PUBSPEC["name"]
VERSION        = PUBSPEC["version"].to_s.split("+").first

# ── Defaults ────────────────────────────────────────────────

ENV["MATCH_TYPE"]                                = "appstore"
ENV["MATCH_READONLY"]                            = "true"
ENV["MATCH_CLONE_BRANCH_DIRECTLY"]               = "true"

ENV["PILOT_IPA"]                                 = "build/ios/ipa/#{APP_NAME}.ipa"
ENV["PILOT_SKIP_WAITING_FOR_BUILD_PROCESSING"]   = "true"

ENV["SUPPLY_TRACK"]                              = "internal"
ENV["SUPPLY_AAB"]                                = "build/app/outputs/bundle/release/app-release.aab"

ENV["DELIVER_APP_VERSION"]                       = VERSION
ENV["DELIVER_PRECHECK_INCLUDE_IN_APP_PURCHASES"] = "false"
ENV["DELIVER_AUTOMATIC_RELEASE"]                 = "true"
ENV["DELIVER_SKIP_BINARY_UPLOAD"]                = "true"
ENV["DELIVER_FORCE"]                             = "true"
ENV["DELIVER_OVERWRITE_SCREENSHOTS"]             = "true"

# ── Lanes ────────────────────────────────────────────────────

lane :deploy do
  deploy_ios
  deploy_android
end

lane :deploy_ios do
  setup_ci
  match
  sh("flutter build ipa --build-number=#{latest_testflight_build_number + 1}")
  pilot
end

lane :deploy_android do
  sh("flutter build appbundle --build-number=#{google_play_track_version_codes.max + 1}")
  supply(
    skip_upload_metadata: true,
    skip_upload_screenshots: true,
    skip_upload_changelogs: true,
  )
end

lane :metadata do
  deliver
  supply(skip_upload_aab: true)
end

# ── Error ────────────────────────────────────────────────────

error do |lane, exception|
  slack(message: exception.message, success: false)
end
