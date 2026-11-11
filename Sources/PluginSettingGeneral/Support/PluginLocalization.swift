import Foundation
import LumiLocalizationKit

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
///
/// 由原 `LumiPluginLocalization` 转发 shim 收敛而来；调用点使用 `pluginLocalization.string(_:)`。
public let pluginLocalization = PluginLocalization(bundle: .module)

/// 带参数本地化的便捷入口。
///
/// `PluginLocalization.string(_:)` 只做「key → 译文」解析，不负责占位符替换。
/// 本扩展补上格式化这一步，让调用点保持 `pluginLocalization.string(key, arg1, arg2)`
/// 这一种形态，与 `String(format:)` 的既有写法语义一致：
///
/// ```swift
/// pluginLocalization.string("%lld of %lld", index + 1, pages.count)
/// ```
///
/// 占位符使用 Foundation 的 `%lld` / `%@` 语法；xcstrings 中若需要调整语序，
/// 使用位置参数形式（如 `%1$lld`）以固定各语言的参数顺序。
extension PluginLocalization {
    /// 解析本地化字符串并按 Foundation 格式化占位符。
    ///
    /// - Parameters:
    ///   - key: 本地化 key；未命中任何语言时原样返回 key。
    ///   - arguments: 依次替换 `%lld` / `%@` 等占位符的值。
    /// - Returns: 格式化后的字符串。
    func string(_ key: String, _ arguments: CVarArg...) -> String {
        let template = string(key)
        guard !arguments.isEmpty else { return template }
        return String(format: template, arguments: arguments)
    }
}
