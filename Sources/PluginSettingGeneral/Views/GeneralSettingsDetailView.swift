import LumiUI
import ProviderAppUpdate
import ProviderDocsView
import ProviderUninstall
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// 通用设置详情视图 —— 设置窗口「通用」标签页：多个分组卡片。
///
/// 只依赖 `GeneralSettingsViewModel`；诊断导出、更新通道、卸载扫描等
/// 业务状态全部由 ViewModel 提供，外部操作经 Capability 收敛。
struct GeneralSettingsDetailView: View {
    let configuration: SettingGeneralConfiguration
    let version: String?
    @ObservedObject var viewModel: GeneralSettingsViewModel

    @State private var isPresentingManuals = false
    @State private var isPresentingUninstall = false

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                manualsSection
                applicationSection
                if let privacyDescription = configuration.privacyDescription {
                    privacySection(privacyDescription)
                }
                if hasAboutLinks {
                    aboutUsSection
                }
                if configuration.showsUpdateChannelSection {
                    updatesSection
                }
                if configuration.showsDiagnosticsSection {
                    diagnosticsSection
                }
                if configuration.showsUninstallSection {
                    uninstallSection
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isPresentingManuals) {
            ManualsBrowserView(manuals: viewModel.manuals)
        }
        .sheet(isPresented: $isPresentingUninstall, onDismiss: {
            viewModel.cancelUninstallScan()
        }) {
            uninstallSheet
        }
    }

    // MARK: - 说明书

    @ViewBuilder
    private var manualsSection: some View {
        if configuration.alwaysShowManualsSection || !viewModel.manuals.isEmpty {
            AppSettingSection(
                title: pluginLocalization.string("User Manual"),
                titleAlignment: .leading
            ) {
                AppSettingRow(
                    title: pluginLocalization.string("Browse Manuals"),
                    description: pluginLocalization.string("Usage guides for every feature."),
                    icon: "book"
                ) {
                    AppButton(
                        pluginLocalization.string("Open"),
                        systemImage: "book.pages",
                        style: .secondary,
                        size: .small
                    ) {
                        isPresentingManuals = true
                    }
                    .disabled(viewModel.manuals.isEmpty)
                }
            }
        }
    }

    // MARK: - 应用信息

    private var applicationSection: some View {
        AppSettingSection(
            title: pluginLocalization.string(configuration.applicationName),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Bundle ID"),
                    description: bundleInfo.bundleIdentifier,
                    icon: "number"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Version"),
                    description: bundleInfo.version ?? pluginLocalization.string("Unknown"),
                    icon: "tag"
                ) {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - 隐私

    /// 隐私说明是一段陈述，不是一个可点开的条目：直接把说明文字放进分组，
    /// 不画图标、不做成行，避免让人以为点得动。
    private func privacySection(_ description: String) -> some View {
        AppSettingSection(
            title: pluginLocalization.string("Privacy"),
            titleAlignment: .leading
        ) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.secondary)
                Text(description)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 关于我们

    /// 「关于我们」分组是否有可展示的条目。
    ///
    /// 三个法律链接一个都没有时不画这个分组 —— 一个只有标题的空分组看起来
    /// 就是渲染错误。
    private var hasAboutLinks: Bool {
        configuration.websiteURLString != nil
            || configuration.privacyPolicyURLString != nil
            || configuration.termsOfServiceURLString != nil
    }

    /// 「关于我们」分组：官网 / 隐私政策 / 服务条款。
    ///
    /// 三个链接各自独立存在，宿主只配了哪个就显示哪个。
    @ViewBuilder
    private var aboutUsSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("About Us"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                if let website = aboutURL(configuration.websiteURLString) {
                    aboutRow(
                        title: pluginLocalization.string("Official Website"),
                        url: website,
                        icon: "globe"
                    )
                    if configuration.privacyPolicyURLString != nil || configuration.termsOfServiceURLString != nil {
                        Divider().padding(.vertical, 8)
                    }
                }
                if let privacy = aboutURL(configuration.privacyPolicyURLString) {
                    aboutRow(
                        title: pluginLocalization.string("Privacy Policy"),
                        url: privacy,
                        icon: "hand.raised"
                    )
                    if configuration.termsOfServiceURLString != nil {
                        Divider().padding(.vertical, 8)
                    }
                }
                if let terms = aboutURL(configuration.termsOfServiceURLString) {
                    aboutRow(
                        title: pluginLocalization.string("Terms of Service"),
                        url: terms,
                        icon: "doc.text"
                    )
                }
            }
        }
    }

    private func aboutRow(title: String, url: URL, icon: String) -> some View {
        AppSettingRow(
            title: title,
            description: url.host ?? url.absoluteString,
            icon: icon
        ) {
            AppButton(
                pluginLocalization.string("Open"),
                systemImage: "arrow.up.forward.square",
                style: .secondary,
                size: .small
            ) {
                openURL(url)
            }
        }
    }

    private func aboutURL(_ string: String?) -> URL? {
        guard let string else { return nil }
        return URL(string: string)
    }

    /// 在默认浏览器中打开链接。
    private func openURL(_ url: URL) {
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #elseif canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }

    // MARK: - 更新通道

    private var updatesSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Updates"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("Check for Updates"),
                description: pluginLocalization.string("Check if a new version is available."),
                icon: "arrow.triangle.2.circlepath"
            ) {
                AppButton(
                    pluginLocalization.string("Check Now"),
                    systemImage: "arrow.triangle.2.circlepath",
                    style: .secondary,
                    size: .small
                ) {
                    viewModel.checkForUpdates()
                }
                .disabled(!viewModel.isUpdateChannelAvailable)
            }

            if viewModel.isUpdateChannelAvailable {
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Update Channel"),
                    description: pluginLocalization.string("Stable builds are recommended. Beta builds contain new features but may be unstable."),
                    icon: "shippingbox"
                ) {
                    Picker(
                        "",
                        selection: $viewModel.selectedUpdateChannel
                    ) {
                        Text(pluginLocalization.string("Stable")).tag(AppUpdateChannel.stable)
                        Text(pluginLocalization.string("Preview")).tag(AppUpdateChannel.preview)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
        }
    }

    // MARK: - 诊断导出

    private var diagnosticsSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Diagnostics"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("Storage"),
                description: pluginLocalization.string(
                    "%@ uses about %@ of disk space to keep its plugins, preferences, and credentials.",
                    configuration.applicationName,
                    viewModel.storageSizeDescription
                ),
                icon: "internaldrive"
            ) {
                AppButton(
                    pluginLocalization.string("Open"),
                    systemImage: "folder",
                    style: .secondary,
                    size: .small
                ) {
                    viewModel.openStorageDirectory()
                }
                .disabled(!viewModel.isStorageAvailable)
            }
            Divider()
                .padding(.vertical, 8)
            AppSettingRow(
                title: pluginLocalization.string("Export Logs"),
                description: pluginLocalization.string(
                    "Export logs and diagnostic information for troubleshooting."
                ),
                icon: "doc.text"
            ) {
                AppButton(
                    viewModel.isExportingDiagnostics
                        ? pluginLocalization.string("Exporting...")
                        : pluginLocalization.string("Export"),
                    systemImage: "square.and.arrow.up",
                    style: .secondary,
                    size: .small
                ) {
                    viewModel.exportDiagnostics()
                }
                .disabled(viewModel.isExportingDiagnostics || !viewModel.isDiagnosticsAvailable)
            }
            if let feedback = viewModel.diagnosticsFeedback {
                Text(feedback)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - 卸载

    private var uninstallSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Uninstall"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string(
                    "Uninstall %@",
                    configuration.applicationName
                ),
                description: pluginLocalization.string(
                    "Removes all %@ data from your Mac.",
                    configuration.applicationName
                ),
                icon: "trash"
            ) {
                AppButton(
                    pluginLocalization.string("Uninstall..."),
                    systemImage: "trash",
                    style: .destructive,
                    size: .small
                ) {
                    isPresentingUninstall = true
                    viewModel.beginUninstall()
                }
                .disabled(!viewModel.isUninstallAvailable)
            }
        }
    }

    private var uninstallSheet: some View {
        UninstallConfirmationView(
            isScanning: viewModel.isScanningUninstall,
            scan: viewModel.uninstallScan,
            removeKeychainCredentials: $viewModel.removeKeychainCredentials,
            removeApplication: $viewModel.removeApplication,
            isUninstalling: viewModel.isUninstalling,
            feedback: viewModel.uninstallFeedback,
            feedbackKind: viewModel.uninstallFeedbackKind,
            configuration: configuration,
            onConfirm: { viewModel.performUninstall() },
            onCancel: { isPresentingUninstall = false }
        )
    }

    // MARK: - Helpers

    private var bundleInfo: GeneralSettingsViewModel.BundleInfo {
        viewModel.bundleInfo
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func uninstallIcon(for target: UninstallTarget) -> String {
        switch target.kind {
        case .keychain: return "key.fill"
        case .application: return "app"
        case .applicationData, .legacyData: return "folder"
        case .caches: return "clock.arrow.circlepath"
        case .appGroup: return "square.stack.3d.up"
        case .preferences: return "slider.horizontal.3"
        }
    }
}
