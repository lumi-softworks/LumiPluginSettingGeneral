import Foundation
import ProviderUninstall

/// 通用设置插件的品牌与功能配置。
///
/// 这个插件在多个同族应用（Lumi、Wakey 等）间共享，但每个应用有自己的品牌文案、
/// 插件 id、日志子系统、以及部分功能的启用/禁用（如「检查更新」在 App Store 分发时不显示）。
///
/// 宿主在装配时传入自己的 `SettingGeneralConfiguration`，本插件据此渲染 UI。
public struct SettingGeneralConfiguration: Sendable {
    /// 插件 id，同时也是插件数据目录名。
    ///
    /// 历史值必须保持不变，否则用户的既有插件数据（偏好、缓存）会换位置。
    public let pluginID: String

    /// 日志子系统，例如 `com.coffic.lumi.plugin.setting-general`。
    public let loggerSubsystem: String

    /// 应用显示名，例如 "Lumi"、"Wakey"。
    ///
    /// 出现在设置页「Lumi / Wakey」标题与卸载摘要里。
    public let applicationName: String

    /// 插件元数据描述，例如 "Registers the General settings entry..."。
    public let description: String

    /// 打开设置窗口的通知名。
    ///
    /// 宿主监听这个通知后打开设置窗口，插件与宿主因此无需互相依赖。
    public let openSettingsNotificationName: String

    /// 卸载流程的品牌配置。
    ///
    /// 决定卸载时广播的通知名、确认短语、目标显示名与白名单。
    public let uninstallBranding: UninstallBranding

    /// 是否显示「更新通道」区块。
    ///
    /// App Store 分发时通常禁用（更新由系统与 App Store 负责），
    /// 自分发时启用（允许用户选择稳定版 / Beta）。
    public let showsUpdateChannelSection: Bool

    /// 是否显示「CLI 安装」区块。
    ///
    /// 仅桌面应用需要，移动端应用禁用。
    public let showsCLIInstallSection: Bool

    /// 「使用手册」区块是否始终显示。
    ///
    /// `true` 表示即使没有说明书也显示空区块（Lumi 行为），
    /// `false` 表示仅在有说明书时显示（Wakey 行为）。
    public let alwaysShowManualsSection: Bool

    public init(
        pluginID: String,
        loggerSubsystem: String,
        applicationName: String,
        description: String,
        openSettingsNotificationName: String,
        uninstallBranding: UninstallBranding,
        showsUpdateChannelSection: Bool = true,
        showsCLIInstallSection: Bool = true,
        alwaysShowManualsSection: Bool = true
    ) {
        self.pluginID = pluginID
        self.loggerSubsystem = loggerSubsystem
        self.applicationName = applicationName
        self.description = description
        self.openSettingsNotificationName = openSettingsNotificationName
        self.uninstallBranding = uninstallBranding
        self.showsUpdateChannelSection = showsUpdateChannelSection
        self.showsCLIInstallSection = showsCLIInstallSection
        self.alwaysShowManualsSection = alwaysShowManualsSection
    }

    /// Lumi 品牌的默认配置。
    public static let lumi = Self(
        pluginID: "com.coffic.lumi.plugin.setting-general",
        loggerSubsystem: "com.coffic.lumi.plugin.setting-general",
        applicationName: "Lumi",
        description: "Registers the General settings entry with app info, website and updates.",
        openSettingsNotificationName: "lumi.openSettings",
        uninstallBranding: .lumi
    )

    /// Wakey 品牌的默认配置。
    ///
    /// 与 Wakey 仓库里迁移前的本地包逐字一致：插件 id、日志子系统、应用名都保持不变，
    /// 且禁用「更新通道」与「CLI 安装」区块（Wakey 通过 App Store 分发，不需要这些）。
    public static let wakey = Self(
        pluginID: "com.coffic.wakey.plugin.setting-general",
        loggerSubsystem: "com.coffic.wakey.plugin.setting-general",
        applicationName: "Wakey",
        description: "Registers the General settings entry with app info, manuals, diagnostics and uninstall.",
        openSettingsNotificationName: "com.coffic.wakey.settings.open",
        uninstallBranding: .wakey,
        showsUpdateChannelSection: false,
        showsCLIInstallSection: false,
        alwaysShowManualsSection: false
    )
}
