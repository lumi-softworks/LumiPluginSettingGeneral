import Foundation
import Testing
@testable import PluginSettingGeneral
import ProviderUninstall

/// 设置插件品牌配置守卫。
///
/// 这些测试确保 SettingGeneralConfiguration.lumi 和 .wakey 与迁移前各仓库的本地包行为一致。
/// 品牌配置决定了插件 id、日志子系统、应用名称等关键属性，改动会影响既有用户的设置数据。
@Suite("设置插件品牌配置")
struct SettingGeneralConfigurationTests {
    @Test("Lumi 品牌配置与迁移前逐字一致")
    func lumiConfigurationIsUnchanged() {
        let config = SettingGeneralConfiguration.lumi
        
        #expect(config.pluginID == "com.coffic.lumi.plugin.setting-general")
        #expect(config.loggerSubsystem == "com.coffic.lumi.plugin.setting-general")
        #expect(config.applicationName == "Lumi")
        #expect(config.description == "Registers the General settings entry with app info, website and updates.")
        #expect(config.openSettingsNotificationName == "lumi.openSettings")
        #expect(config.uninstallBranding == .lumi)
        #expect(config.showsUpdateChannelSection == true)
        #expect(config.showsCLIInstallSection == true)
        #expect(config.alwaysShowManualsSection == true)
    }
    
    @Test("Wakey 品牌配置与迁移前逐字一致")
    func wakeyConfigurationIsUnchanged() {
        let config = SettingGeneralConfiguration.wakey
        
        #expect(config.pluginID == "com.coffic.wakey.plugin.setting-general")
        #expect(config.loggerSubsystem == "com.coffic.wakey.plugin.setting-general")
        #expect(config.applicationName == "Wakey")
        #expect(config.description == "Registers the General settings entry with app info, manuals, diagnostics and uninstall.")
        #expect(config.openSettingsNotificationName == "com.coffic.wakey.settings.open")
        #expect(config.uninstallBranding == .wakey)
        #expect(config.showsUpdateChannelSection == false)
        #expect(config.showsCLIInstallSection == false)
        #expect(config.alwaysShowManualsSection == false)
    }
    
    @Test("插件 ID 决定数据存储路径")
    func pluginIDDeterminesStoragePath() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        // 不同的 pluginID 意味着不同的数据目录
        #expect(lumiConfig.pluginID != wakeyConfig.pluginID)
        
        // 这确保了迁移后用户的历史设置数据不会丢失
        #expect(lumiConfig.pluginID.contains("lumi"))
        #expect(wakeyConfig.pluginID.contains("wakey"))
    }
    
    @Test("日志子系统与应用绑定")
    func loggerSubsystemIsApplicationBound() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        #expect(lumiConfig.loggerSubsystem.contains("lumi"))
        #expect(wakeyConfig.loggerSubsystem.contains("wakey"))
        
        // 日志子系统应该与 pluginID 保持一致
        #expect(lumiConfig.loggerSubsystem == lumiConfig.pluginID)
        #expect(wakeyConfig.loggerSubsystem == wakeyConfig.pluginID)
    }
    
    @Test("设置打开通知名与应用绑定")
    func openSettingsNotificationIsApplicationBound() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        #expect(lumiConfig.openSettingsNotificationName.contains("lumi"))
        #expect(wakeyConfig.openSettingsNotificationName.contains("wakey"))
        
        // 通知名应该不同，避免两个应用互相触发
        #expect(lumiConfig.openSettingsNotificationName != wakeyConfig.openSettingsNotificationName)
    }
    
    @Test("卸载品牌与配置匹配")
    func uninstallBrandingMatchesConfiguration() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        #expect(lumiConfig.uninstallBranding == .lumi)
        #expect(wakeyConfig.uninstallBranding == .wakey)
        
        // 确认短语应该与应用名称匹配
        #expect(lumiConfig.uninstallBranding.confirmationPhrase.contains("Lumi"))
        #expect(wakeyConfig.uninstallBranding.confirmationPhrase.contains("Wakey"))
    }
    
    @Test("区块显示配置符合应用分发方式")
    func sectionVisibilityMatchesDistributionMethod() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        // Lumi 通过直接分发，显示更新通道和 CLI 安装
        #expect(lumiConfig.showsUpdateChannelSection == true)
        #expect(lumiConfig.showsCLIInstallSection == true)
        
        // Wakey 通过 App Store 分发，不显示更新通道和 CLI 安装
        #expect(wakeyConfig.showsUpdateChannelSection == false)
        #expect(wakeyConfig.showsCLIInstallSection == false)
    }
    
    @Test("使用手册区块显示策略")
    func manualsSectionVisibilityStrategy() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        // Lumi 始终显示使用手册区块
        #expect(lumiConfig.alwaysShowManualsSection == true)
        
        // Wakey 仅在有说明书时显示
        #expect(wakeyConfig.alwaysShowManualsSection == false)
    }
    
    @Test("应用名称用于 UI 展示")
    func applicationNameUsedForUIDisplay() {
        let lumiConfig = SettingGeneralConfiguration.lumi
        let wakeyConfig = SettingGeneralConfiguration.wakey
        
        #expect(lumiConfig.applicationName == "Lumi")
        #expect(wakeyConfig.applicationName == "Wakey")
        
        // 应用名称用于多个 UI 元素：
        // 1. 设置页标题
        // 2. 卸载确认对话框
        // 3. 诊断导出文件描述
        #expect(!lumiConfig.applicationName.isEmpty)
        #expect(!wakeyConfig.applicationName.isEmpty)
    }
}
