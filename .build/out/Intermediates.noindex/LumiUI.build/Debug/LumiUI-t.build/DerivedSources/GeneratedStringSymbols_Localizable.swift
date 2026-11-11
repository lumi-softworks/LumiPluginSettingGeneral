// 
// GeneratedStringSymbols_Localizable.swift
// Auto-Generated symbols for localized strings defined in “Localizable.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private nonisolated let resourceBundle = Foundation.Bundle.module
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.atURL(resourceBundle.bundleURL)
#else

private class ResourceBundleClass {}
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.forClass(ResourceBundleClass.self)
#endif

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
nonisolated extension LocalizedStringResource {
    /**
     Localized string for key “Activity on %@: level %lld” in table “Localizable.xcstrings”.
     */
    static func activityOnLevel(_ arg1: String, _ arg2: Int) -> LocalizedStringResource {
        LocalizedStringResource("Activity on %@: level %lld", defaultValue: "\(arg1)\(arg2, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Add” in table “Localizable.xcstrings”.
     */
    static var add: LocalizedStringResource {
        LocalizedStringResource("Add", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Connection timeout” in table “Localizable.xcstrings”.
     */
    static var connectionTimeout: LocalizedStringResource {
        LocalizedStringResource("Connection timeout", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Done” in table “Localizable.xcstrings”.
     */
    static var done: LocalizedStringResource {
        LocalizedStringResource("Done", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Enter name” in table “Localizable.xcstrings”.
     */
    static var enterName: LocalizedStringResource {
        LocalizedStringResource("Enter name", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Failed to load data” in table “Localizable.xcstrings”.
     */
    static var failedToLoadData: LocalizedStringResource {
        LocalizedStringResource("Failed to load data", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Last 24 hours” in table “Localizable.xcstrings”.
     */
    static var last24Hours: LocalizedStringResource {
        LocalizedStringResource("Last 24 hours", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Less” in table “Localizable.xcstrings”.
     */
    static var less: LocalizedStringResource {
        LocalizedStringResource("Less", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Model” in table “Localizable.xcstrings”.
     */
    static var model: LocalizedStringResource {
        LocalizedStringResource("Model", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “More” in table “Localizable.xcstrings”.
     */
    static var more: LocalizedStringResource {
        LocalizedStringResource("More", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Plugin-specific options” in table “Localizable.xcstrings”.
     */
    static var pluginSpecificOptions: LocalizedStringResource {
        LocalizedStringResource("Plugin-specific options", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Shared section styling” in table “Localizable.xcstrings”.
     */
    static var sharedSectionStyling: LocalizedStringResource {
        LocalizedStringResource("Shared section styling", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Status” in table “Localizable.xcstrings”.
     */
    static var status: LocalizedStringResource {
        LocalizedStringResource("Status", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Localized string for key “Tokens” in table “Localizable.xcstrings”.
     */
    static var tokens: LocalizedStringResource {
        LocalizedStringResource("Tokens", table: "Localizable", bundle: resourceBundleDescription)
    }
}