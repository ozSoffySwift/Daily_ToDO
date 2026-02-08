//
//  RecurrenceRule.swift
//  DailyToDo
//
//  App-wide display helpers.
//

import Foundation

enum AppInfo {
    static let appName = "Daily Todo"
    static let developerName = "Oz Soffy"

    static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

enum AppLinks {
    static let linkedIn = URL(string: "https://www.linkedin.com")!
    static let facebook = URL(string: "https://www.facebook.com")!
    static let instagram = URL(string: "https://www.instagram.com")!
    static let twitter = URL(string: "https://x.com")!
}
