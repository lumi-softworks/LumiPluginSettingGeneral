import LumiUI
import ProviderUninstall
import SwiftUI

/// 卸载确认视图：扫描结果 + 选项 + 确认/取消按钮。
///
/// 在 `.sheet` 中呈现，让用户选择要删除的内容（Keychain、应用本体等），
/// 然后显示扫描结果并等待确认。
struct UninstallConfirmationView: View {
    @LumiTheme private var theme

    let isScanning: Bool
    let scan: UninstallScan?
    @Binding var removeKeychainCredentials: Bool
    @Binding var removeApplication: Bool
    let isUninstalling: Bool
    let feedback: String?
    let feedbackKind: UninstallFeedbackKind
    let configuration: SettingGeneralConfiguration
    let onConfirm: @MainActor () -> Void
    let onCancel: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    optionsSection
                    if let scan {
                        scanSummary(scan: scan)
                    }
                    if let feedback {
                        feedbackSection(text: feedback)
                    }
                }
                .padding(24)
            }

            Divider()

            buttonBar
                .padding(16)
        }
        .frame(width: 560, height: 480)
        .background(theme.surface)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pluginLocalization.string("Uninstall \(configuration.applicationName)"))
                .font(.appTitle)
            Text(pluginLocalization.string(
                "This will remove all \(configuration.applicationName) data from your Mac."
            ))
            .font(.appBody)
            .foregroundStyle(.secondary)
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(
                pluginLocalization.string("Also delete API Keys, passwords, and credentials from Keychain"),
                isOn: $removeKeychainCredentials
            )
            .font(.appBody)

            Toggle(
                pluginLocalization.string("Also move the \(configuration.applicationName) app to Trash"),
                isOn: $removeApplication
            )
            .font(.appBody)
        }
    }

    @ViewBuilder
    private func scanSummary(scan: UninstallScan) -> some View {
        AppSettingSection(
            title: String(
                format: pluginLocalization.string("Will process %lld items of %@ data, %@ in total."),
                scan.targets.count,
                configuration.applicationName,
                formattedBytes(scan.totalSizeInBytes)
            ),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                ForEach(Array(scan.targets.prefix(8).enumerated()), id: \.element.id) { index, target in
                    AppSettingRow(
                        title: target.kind.displayName(branding: configuration.uninstallBranding),
                        description: target.sizeInBytes > 0 ? formattedBytes(target.sizeInBytes) : "—",
                        icon: uninstallIcon(for: target)
                    ) {
                        EmptyView()
                    }

                    if index < min(scan.targets.count, 8) - 1 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }

                if scan.targets.count > 8 {
                    Text(String(
                        format: pluginLocalization.string("%lld more items will be processed after confirmation."),
                        scan.targets.count - 8
                    ))
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackSection(text: String) -> some View {
        Text(text)
            .font(.appBody)
            .foregroundStyle(feedbackKind == .warning ? .red : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttonBar: some View {
        HStack {
            Spacer()
            AppButton(pluginLocalization.string("Cancel"), style: .ghost, size: .small) {
                onCancel()
            }
            AppButton(
                isUninstalling
                    ? pluginLocalization.string("Uninstalling...")
                    : (removeApplication
                        ? pluginLocalization.string("Permanent Delete and Uninstall")
                        : pluginLocalization.string("Clear Data and Quit")),
                systemImage: isUninstalling ? "hourglass" : "trash.fill",
                style: .destructive,
                size: .small
            ) {
                onConfirm()
            }
            .disabled(isUninstalling || isScanning)
        }
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
