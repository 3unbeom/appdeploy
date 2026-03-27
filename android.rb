require 'fastlane/plugin/firebase_app_distribution'

platform :android do
  lane :beta do
    sh("cd ../.. && flutter build apk")
    firebase_app_distribution(
      apk_path: "../build/app/outputs/flutter-apk/app-release.apk",
      release_notes: changelog_from_git_commits(commits_count: 3),
      groups: "testers",
      service_credentials_json_data: ENV["SUPPLY_JSON_KEY_DATA"],
    )
    slack
  end

  lane :release do
    sh("cd ../.. && flutter build appbundle --build-number=#{google_play_track_version_codes.max + 1}")
    supply(aab: "../build/app/outputs/bundle/release/app-release.aab")
    slack
  end
end

error do |lane, exception|
  slack(message: exception.message, success: false)
end
