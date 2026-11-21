import LumiUI
import ProviderDocsView
import SwiftUI

/// 说明书浏览器 —— 主从式布局：左侧为提供了说明书的插件名列表，
/// 右侧为选中插件的说明书内容。
struct ManualsBrowserView: View {
    let manuals: [DocsEntry]

    @State private var selectedID: String?

    @Environment(\.dismiss) private var dismiss

    private var selectedManual: DocsEntry? {
        manuals.first { $0.id == selectedID } ?? manuals.first
    }

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    // MARK: - macOS

    private var macBody: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(minWidth: 860, minHeight: 560)
        .onAppear(perform: selectFirstManualIfNeeded)
    }

    // MARK: - iOS

    #if os(iOS)
    /// iOS 上没有横向空间容纳「列表 + 内容」双栏：改为标准的分层导航，
    /// 手册列表 push 到内容页。
    private var iosBody: some View {
        NavigationStack {
            Group {
                if manuals.isEmpty {
                    ContentUnavailableView(
                        pluginLocalization.string("No user manual yet."),
                        systemImage: "book"
                    )
                } else {
                    List(manuals) { manual in
                        NavigationLink {
                            ScrollView {
                                manual.makeView()
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .navigationTitle(manual.name)
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Label(manual.name, systemImage: "book")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(pluginLocalization.string("User Manual"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(pluginLocalization.string("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear(perform: selectFirstManualIfNeeded)
    }
    #endif

    private func selectFirstManualIfNeeded() {
        if selectedID == nil {
            selectedID = manuals.first?.id
        }
    }

    // MARK: - 左侧插件列表

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "book")
                    .foregroundStyle(.secondary)
                Text(pluginLocalization.string("User Manual"))
                    .font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(manuals) { manual in
                        sidebarRow(manual)
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 220)
        .background(Color.primary.opacity(0.03))
    }

    private func sidebarRow(_ manual: DocsEntry) -> some View {
        let isSelected = manual.id == selectedManual?.id
        return Button {
            selectedID = manual.id
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "book")
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(manual.name)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 右侧说明书内容

    private var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let manual = selectedManual {
                HStack(spacing: 10) {
                    Text(manual.name)
                        .font(.headline)
                    Spacer()
                    AppIconButton(systemImage: "xmark") {
                        dismiss()
                    }
                }
                .padding(16)

                Divider()

                ScrollView {
                    manual.makeView()
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text(pluginLocalization.string("No user manual yet."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
