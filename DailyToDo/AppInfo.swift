//
//  AppInfo.swift
//  DailyToDo
//
//  App-wide display helpers.
//

import Foundation

/// Static display metadata about the app, used on the About screen.
enum AppInfo {
    /// The user-facing app name shown on the About screen.
    static let appName = "Daily 2do"
    /// The developer name shown on the About screen.
    static let developerName = "Oz Soffy"

    /// The formatted "version (build)" string, e.g. "1.1 (1)", read from the app's Info.plist.
    static var versionString: String {
        // CFBundleShortVersionString is the marketing version (e.g. "1.1").
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        // CFBundleVersion is the internal build number (e.g. "1").
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// External social links shown on the About screen.
enum AppLinks {
    /// Link to the developer's LinkedIn profile.
    static let linkedIn = URL(string: "https://www.linkedin.com")!
    /// Link to the developer's Facebook profile.
    static let facebook = URL(string: "https://www.facebook.com")!
    /// Link to the developer's Instagram profile.
    static let instagram = URL(string: "https://www.instagram.com")!
    /// Link to the developer's Twitter/X profile.
    static let twitter = URL(string: "https://x.com")!
}
