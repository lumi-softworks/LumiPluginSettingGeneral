import Foundation
import Testing
@testable import PluginSettingGeneral

/// String Catalog 覆盖度守卫。
///
/// 历史问题：catalog 里只有 Lumi 遗留的「中文当 key」条目，而代码用的是英文 key，
/// 于是中文环境下「通用」设置页大面积回退显示英文原文（`User Manual`、
/// `Diagnostics`、`Storage`、`Export Logs` …）。
///
/// 这个测试把「代码里用到的每个 key 必须在 catalog 里有 en / zh-Hans / zh-Hant 译文」
/// 变成硬约束，避免后续再出现「加了文案但忘了登记进 catalog」。
@Suite("String Catalog 覆盖度")
struct LocalizationCatalogCoverageTests {
    /// 代码中实际使用的全部本地化 key。
    ///
    /// 手工维护而非扫描源码：扫描需要读源文件，在 SPM 沙箱里不可靠；
    /// 而这份清单本身就是「这个插件到底用了哪些文案」的显式契约。
    static let usedKeys: Set<String> = [
        // 设置入口
        "General",
        "General Settings",
        "Settings...",
        // 说明书
        "User Manual",
        "Browse Manuals",
        "Usage guides for every feature.",
        "No user manual yet.",
        // 应用信息
        "Bundle ID",
        "Version",
        "Unknown",
        // 更新通道
        "Updates",
        "Check for Updates",
        "Check if a new version is available.",
        "Check Now",
        "Update Channel",
        "Stable builds are recommended. Beta builds contain new features but may be unstable.",
        "Stable",
        "Preview",
        // 诊断与存储
        "Diagnostics",
        "Storage",
        "%@ uses about %@ of disk space to keep its plugins, preferences, and credentials.",
        "Storage service is unavailable.",
        "Calculating...",
        "Open",
        // 导出日志
        "Export Logs",
        "Export logs and diagnostic information for troubleshooting.",
        "Export",
        "Exporting...",
        "Choose where to save the diagnostics log",
        "Export cancelled.",
        "Logs exported: %@",
        "Export failed: %@",
        "Log service is unavailable.",
        // 卸载
        "Uninstall",
        "Uninstall %@",
        "Removes all %@ data from your Mac.",
        "This will remove all %@ data from your Mac.",
        "Also delete API Keys, passwords, and credentials from Keychain",
        "Also move the %@ app to Trash",
        "Will process %lld items of %@ data, %@ in total.",
        "%lld more items will be processed after confirmation.",
        "Cancel",
        "Uninstalling...",
        "Uninstalling %@...",
        "Permanent Delete and Uninstall",
        "Clear Data and Quit",
        "Uninstall...",
        "Uninstall service is unavailable.",
        "Uninstall failed: %@",
        // 卸载浮层
        "This action cannot be undone",
        "Clearing plugin data, preferences, extension data, and credentials.",
        "Uninstall Complete",
        "%@ has been removed from your Mac and moved to Trash.",
        "%@ data has been cleared. The app will now quit.",
        "s until auto-quit",
        "Uninstall Incomplete",
        "Some data could not be cleared. The app was not removed.",
        "Some data could not be cleared. The app was not removed:\n%@",
        "Close",
        // 旧版兼容键
        "%lld",
        "%lld of %lld",
        // CLI 安装（Lumi 品牌共用）
        "Command Line Tool",
        "Add %@ to your PATH to use the command right away.",
        "Install",
        "Install the lumi command to open directories from the terminal.",
        "Installed at %@",
        "Not Installed",
        "The lumi command is ready to use.",
        "Installation failed: %@",
        "Check...",
        "Checking...",
        "Build",
        "Name",
        "Lumi",
        "Registers the General settings entry with app info, website and updates.",
    ]

    /// 源 String Catalog 的路径。
    ///
    /// 用 `#filePath` 反推仓库内路径，而不是 `Bundle.module`：
    /// xcstrings 会被编译成各语言的 `.lproj/*.strings`，源文件并不在 bundle 里。
    private static var sourceCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // PluginSettingGeneralTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // 包根
            .appendingPathComponent("Sources/PluginSettingGeneral/Resources/Localizable.xcstrings")
    }

    /// 读取源 String Catalog，返回 key → 语言 → 译文。
    private static func loadSourceCatalog() throws -> [String: [String: String]] {
        let url = sourceCatalogURL
        let data = try Data(contentsOf: url)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any],
            "\(url.lastPathComponent) 不是合法 JSON"
        )
        let strings = try #require(json["strings"] as? [String: Any], "catalog 缺少 strings 字段")

        var result: [String: [String: String]] = [:]
        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else {
                continue
            }
            var values: [String: String] = [:]
            for (language, unit) in localizations {
                guard let unit = unit as? [String: Any],
                      let stringUnit = unit["stringUnit"] as? [String: Any],
                      let text = stringUnit["value"] as? String else {
                    continue
                }
                values[language] = text
            }
            result[key] = values
        }
        return result
    }

    /// 读取编译产物中某个语言目录的字符串表。
    ///
    /// 这是「用户真正看到的文案」——xcstrings 编译后会被拆成各语言的
    /// `.lproj/Localizable.strings`。
    private static func loadCompiledStrings(language: String) throws -> [String: String] {
        guard let path = Bundle.module.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: path),
              let url = languageBundle.url(forResource: "Localizable", withExtension: "strings") else {
            throw CatalogError.missingLanguageDirectory(language)
        }
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        guard let dictionary = plist as? [String: String] else {
            throw CatalogError.unexpectedStringsFormat(language)
        }
        return dictionary
    }

    enum CatalogError: Error {
        case missingLanguageDirectory(String)
        case unexpectedStringsFormat(String)
    }

    // MARK: - 源 catalog 的静态检查

    @Test("代码用到的每个 key 都在源 catalog 里")
    func everyUsedKeyExistsInCatalog() throws {
        let catalog = try Self.loadSourceCatalog()
        let missing = Self.usedKeys.subtracting(Set(catalog.keys)).sorted()
        #expect(
            missing.isEmpty,
            "catalog 缺少这些 key（中文环境会回退显示英文原文）：\(missing)"
        )
    }

    @Test("每个 key 都有 en / zh-Hans / zh-Hant 译文")
    func everyUsedKeyIsTranslated() throws {
        let catalog = try Self.loadSourceCatalog()
        var incomplete: [String] = []
        for key in Self.usedKeys.sorted() {
            guard let values = catalog[key] else { continue }
            for language in ["en", "zh-Hans", "zh-Hant"] {
                guard let text = values[language], !text.isEmpty else {
                    incomplete.append("\(key)[\(language)]")
                    continue
                }
            }
        }
        #expect(
            incomplete.isEmpty,
            "这些 key 缺少 en / zh-Hans / zh-Hant 译文：\(incomplete)"
        )
    }

    @Test("源 catalog 里没有把中文当成 key 的脏条目")
    func catalogHasNoChineseAsKey() throws {
        let catalog = try Self.loadSourceCatalog()
        let offenders = catalog.keys
            .filter { key in key.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF } }
            .sorted()
        #expect(
            offenders.isEmpty,
            "这些条目以中文为 key，代码用的却是英文 key，永远查不到译文：\(offenders)"
        )
    }

    // MARK: - 编译产物的运行时检查

    @Test("编译产物里中文表覆盖全部 key")
    func compiledChineseTableCoversEveryKey() throws {
        let chinese = try Self.loadCompiledStrings(language: "zh-Hans")
        let missing = Self.usedKeys.subtracting(Set(chinese.keys)).sorted()
        #expect(
            missing.isEmpty,
            "编译后的 zh-Hans 字符串表缺少这些 key，中文环境会显示英文原文：\(missing)"
        )
    }

    @Test("编译产物里繁体表覆盖全部 key")
    func compiledTraditionalChineseTableCoversEveryKey() throws {
        let traditional = try Self.loadCompiledStrings(language: "zh-Hant")
        let missing = Self.usedKeys.subtracting(Set(traditional.keys)).sorted()
        #expect(
            missing.isEmpty,
            "编译后的 zh-Hant 字符串表缺少这些 key，繁体环境会显示英文原文：\(missing)"
        )
    }

    @Test("运行时解析确实返回中文而非 key 原文")
    func runtimeResolutionReturnsChinese() throws {
        // 抽样几个曾经回退英文的 key。
        let samples = [
            "User Manual": "说明书",
            "Diagnostics": "诊断日志",
            "Storage": "占用空间",
            "Export Logs": "导出日志",
            "Browse Manuals": "浏览说明书",
        ]
        for (key, expected) in samples {
            let resolved = pluginLocalization.string(key, locale: Locale(identifier: "zh-Hans"))
            #expect(
                resolved == expected,
                "\(key) 在中文环境下解析为「\(resolved)」，期望「\(expected)」"
            )
        }
    }
}
