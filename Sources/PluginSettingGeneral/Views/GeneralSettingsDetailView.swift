import LumiUI
import ProviderAppUpdate
import ProviderDocsView
import ProviderUninstall
import SwiftUI

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
                if configuration.showsUpdateChannelSection {
                    updatesSection
                }
                diagnosticsSection
                uninstallSection
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
