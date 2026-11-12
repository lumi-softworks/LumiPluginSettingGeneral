import Darwin
import Foundation
import LumiUI
import ProviderAppUpdate
import ProviderDocsView
import ProviderUninstall
import SwiftUI

/// 通用设置页的唯一数据来源。
///
/// 负责诊断导出、更新通道、卸载扫描/执行等业务状态；所有外部操作
/// 经各 `GeneralSettings*Capability` 收敛，View 只读取本 ViewModel。
@MainActor
final class GeneralSettingsViewModel: ObservableObject {
    struct BundleInfo {
        var bundleIdentifier: String? {
            Bundle.main.bundleIdentifier
        }

        var version: String? {
            let info = Bundle.main.infoDictionary
            let short = info?["CFBundleShortVersionString"] as? String
            let build = info?["CFBundleVersion"] as? String
            switch (short, build) {
            case let (s?, b?):
                return s == b ? s : "\(s) (\(b))"
            case let (s?, nil):
                return s
            case let (nil, b?):
                return b
            default:
                return nil
            }
        }
    }

    let configuration: SettingGeneralConfiguration

    private let docsCapability: any GeneralSettingsDocsCapability
    private let updateChannelCapability: any GeneralSettingsUpdateChannelCapability
    private let diagnosticsCapability: any GeneralSettingsDiagnosticsCapability
    private let storageCapability: any GeneralSettingsStorageCapability
    private let uninstallCapability: any GeneralSettingsUninstallCapability

    /// 所有提供了说明书的文档条目。
    @Published private(set) var manuals: [DocsEntry] = []

    /// 应用数据根目录的实际磁盘占用；nil 表示仍在计算或存储服务不可用。
    @Published private(set) var storageSizeInBytes: Int64?

    /// 当前更新通道（默认稳定版）。
    @Published var selectedUpdateChannel: AppUpdateChannel = .stable {
        didSet {
            guard selectedUpdateChannel != oldValue else { return }
            updateChannelCapability.setUpdateChannel(selectedUpdateChannel)
        }
    }

    // 诊断导出
    @Published private(set) var isExportingDiagnostics = false
    @Published private(set) var diagnosticsFeedback: String?

    // 卸载流程
    @Published var removeKeychainCredentials = true
    @Published var removeApplication = true

    /// 当前卸载扫描任务及其代次。
    ///
    /// 弹窗取消后会重新开始扫描；旧任务即使晚到也不能覆盖新结果或清除
    /// 新扫描的加载态，因此写回前必须比对代次。
    private var uninstallScanTask: Task<Void, Never>?
    private var uninstallScanGeneration = 0

    @Published private(set) var isScanningUninstall = false
    @Published private(set) var uninstallScan: UninstallScan?
    @Published private(set) var isUninstalling = false
    @Published private(set) var uninstallFeedback: String?
    @Published private(set) var uninstallFeedbackKind: UninstallFeedbackKind = .info

    init(
        configuration: SettingGeneralConfiguration,
        docsCapability: any GeneralSettingsDocsCapability,
        updateChannelCapability: any GeneralSettingsUpdateChannelCapability,
        diagnosticsCapability: any GeneralSettingsDiagnosticsCapability,
        storageCapability: any GeneralSettingsStorageCapability,
        uninstallCapability: any GeneralSettingsUninstallCapability
    ) {
        self.configuration = configuration
        self.docsCapability = docsCapability
        self.updateChannelCapability = updateChannelCapability
        self.diagnosticsCapability = diagnosticsCapability
        self.storageCapability = storageCapability
        self.uninstallCapability = uninstallCapability
        refreshManuals()
        selectedUpdateChannel = updateChannelCapability.updateChannel
        refreshStorageUsage()
    }

    // MARK: - 派生状态

    var isUpdateChannelAvailable: Bool {
        updateChannelCapability.isUpdateChannelAvailable
    }

    var isDiagnosticsAvailable: Bool {
        diagnosticsCapability.isDiagnosticsAvailable
    }

    var isStorageAvailable: Bool {
        storageCapability.isStorageAvailable
    }

    var isUninstallAvailable: Bool {
        uninstallCapability.isUninstallAvailable
    }

    var bundleInfo: BundleInfo {
        BundleInfo()
    }

    var storageSizeDescription: String {
        guard isStorageAvailable else { return pluginLocalization.string("Storage service is unavailable.") }
        guard let storageSizeInBytes else { return pluginLocalization.string("Calculating...") }
        return ByteCountFormatter.string(fromByteCount: storageSizeInBytes, countStyle: .file)
    }

    // MARK: - 操作

    func refreshManuals() {
        manuals = docsCapability.manuals
    }

    func refreshStorageUsage() {
        guard isStorageAvailable else {
            storageSizeInBytes = nil
            return
        }
        storageSizeInBytes = nil
        Task { @MainActor in
            storageSizeInBytes = await storageCapability.storageSizeInBytes()
        }
    }

    func openStorageDirectory() {
        storageCapability.openStorageDirectory()
    }

    /// 检查更新：广播 `checkForUpdates` 通知，由宿主（如 Sparkle 更新插件）消费。
    func checkForUpdates() {
        NotificationCenter.default.post(
            name: Notification.Name("checkForUpdates"),
            object: nil
        )
    }

    func exportDiagnostics() {
        guard isDiagnosticsAvailable else {
            diagnosticsFeedback = pluginLocalization.string("Log service is unavailable.")
            return
        }

        isExportingDiagnostics = true
        diagnosticsFeedback = nil

        Task { @MainActor in
            defer { isExportingDiagnostics = false }

            do {
                let archive = try await diagnosticsCapability.makeDiagnosticsArchive()
                defer { try? FileManager.default.removeItem(at: archive.url) }
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.zip]
                panel.canCreateDirectories = true
                panel.nameFieldStringValue = archive.filename
                panel.message = pluginLocalization.string("Choose where to save the diagnostics log")

                guard panel.runModal() == .OK, let destination = panel.url else {
                    diagnosticsFeedback = pluginLocalization.string("Export cancelled.")
                    return
                }

                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: archive.url, to: destination)
                diagnosticsFeedback = pluginLocalization.string(
                    "Logs exported: %@",
                    destination.lastPathComponent
                )
            } catch {
                diagnosticsFeedback = pluginLocalization.string(
                    "Export failed: %@",
                    error.localizedDescription
                )
            }
        }
    }

    func beginUninstall() {
        guard isUninstallAvailable else {
            uninstallFeedback = pluginLocalization.string("Uninstall service is unavailable.")
            uninstallFeedbackKind = .warning
            return
        }

        uninstallScanTask?.cancel()
        uninstallScanTask = nil
        uninstallScanGeneration &+= 1
        let generation = uninstallScanGeneration

        uninstallFeedback = nil
        uninstallFeedbackKind = .info
        removeKeychainCredentials = true
        removeApplication = true
        uninstallScan = nil
        isScanningUninstall = true

        uninstallScanTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let scan = await uninstallCapability.scanUninstall()
            guard uninstallScanGeneration == generation else { return }
            uninstallScan = scan
            isScanningUninstall = false
            uninstallScanTask = nil
        }
    }

    /// 关闭卸载弹窗时调用：取消在途扫描并使其结果失效。
    ///
    /// 只清理由本代扫描产生的状态；重新打开弹窗会从 `beginUninstall()` 开始新一轮。
    func cancelUninstallScan() {
        uninstallScanTask?.cancel()
        uninstallScanTask = nil
        uninstallScanGeneration &+= 1
        isScanningUninstall = false
        uninstallScan = nil
    }

    func performUninstall() {
        guard isUninstallAvailable else {
            uninstallFeedback = pluginLocalization.string("Uninstall service is unavailable.")
            uninstallFeedbackKind = .warning
            return
        }

        isUninstalling = true
        uninstallFeedback = nil
        uninstallFeedbackKind = .info

        // 关闭确认弹窗，隐藏设置窗口，切换到与主窗口解耦的独立卸载浮层。
        // 内核停止后设置窗口可能暂时失去内容，浮层负责承载后续所有阶段。
        NSApp.windows.forEach { $0.orderOut(nil) }
        UninstallOverlayWindowController.shared.show(
            phase: .running,
            configuration: configuration,
            onExit: { [weak self] in self?.terminateAfterUninstall() },
            onClose: {
                UninstallOverlayWindowController.shared.close()
                self.restoreApplicationAfterUninstallFailure()
            }
        )
        NotificationCenter.default.post(
            name: .willUninstall(branding: configuration.uninstallBranding),
            object: nil
        )

        Task { @MainActor in
            defer { isUninstalling = false }
            do {
                await uninstallCapability.prepareForUninstall()
                let result = try await uninstallCapability.uninstall(options: UninstallOptions(
                    confirmation: configuration.uninstallBranding.confirmationPhrase,
                    removeKeychainCredentials: removeKeychainCredentials,
                    removeApplication: removeApplication
                ))

                if result.succeeded {
                    UninstallOverlayWindowController.shared.update(
                        phase: .succeeded(applicationMovedToTrash: result.applicationMovedToTrash)
                    )
                } else {
                    // 明细行来自系统错误（`error.localizedDescription`），随系统语言变化，
                    // 因此只本地化引导句，保留原始明细以免丢失排查线索。
                    let details = result.failures
                        .map { "\($0.location)：\($0.message)" }
                        .joined(separator: "\n")
                    UninstallOverlayWindowController.shared.update(
                        phase: .failed(
                            detail: pluginLocalization.string(
                                "Some data could not be cleared. The app was not removed:\n%@",
                                details
                            )
                        )
                    )
                }
            } catch {
                UninstallOverlayWindowController.shared.update(
                    phase: .failed(
                        detail: pluginLocalization.string(
                            "Uninstall failed: %@",
                            error.localizedDescription
                        )
                    )
                )
            }
        }
    }

    // MARK: - 收尾

    private func terminateAfterUninstall() {
        #if canImport(AppKit)
        NSApp.terminate(nil)
        #endif
    }

    private func restoreApplicationAfterUninstallFailure() {
        #if canImport(AppKit)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
        #endif
    }
}

/// 卸载反馈的视觉语义：`.info` 为中性提示，`.warning` 为警示色。
enum UninstallFeedbackKind {
    case info
    case warning
}
