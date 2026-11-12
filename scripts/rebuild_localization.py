#!/usr/bin/env python3
"""重建 LumiPluginSettingGeneral 的 String Catalog。

旧 catalog 有两个严重问题，导致中文环境下「通用」设置页大量回退英文：

1. 绝大多数条目是「中文当 key」的脏数据（如 `占用空间`、`说明书`），
   代码里实际用的是英文 key，于是查不到译文直接显示英文原文。
2. Wakey 需要的 41 个 key（`User Manual` / `Diagnostics` / `Storage` …）
   根本没有收录。

本脚本按代码实际使用的 key 重建 catalog，为每条补齐
en / zh-Hans / zh-Hant / zh-HK / zh-TW 五种语言。
"""

import json
import pathlib

CATALOG = pathlib.Path("Sources/PluginSettingGeneral/Resources/Localizable.xcstrings")

# key -> (en, zh-Hans, zh-Hant)
#
# zh-HK / zh-TW 与 zh-Hant 共用繁体译文：上游既有 catalog 就是这么组织的，
# 同一份繁体文案在三个标签下保持一致，避免某一种标签下退回英文。
TRANSLATIONS = {
    # MARK: - 设置入口
    "General": ("General", "通用", "一般"),
    "General Settings": ("General Settings", "通用设置", "一般設定"),
    "Settings...": ("Settings...", "设置…", "設定…"),
    # MARK: - 说明书
    "User Manual": ("User Manual", "说明书", "使用手冊"),
    "Browse Manuals": ("Browse Manuals", "浏览说明书", "瀏覽使用手冊"),
    "Usage guides for every feature.": (
        "Usage guides for every feature.",
        "各功能的使用指南。",
        "各功能的使用指南。",
    ),
    "No user manual yet.": (
        "No user manual yet.",
        "暂时还没有说明书。",
        "暫時還沒有使用手冊。",
    ),
    # MARK: - 应用信息
    "Bundle ID": ("Bundle ID", "Bundle ID", "Bundle ID"),
    "Version": ("Version", "版本", "版本"),
    "Unknown": ("Unknown", "未知", "未知"),
    # MARK: - 更新通道
    "Updates": ("Updates", "更新", "更新"),
    "Check for Updates": ("Check for Updates", "检查更新", "檢查更新"),
    "Check if a new version is available.": (
        "Check if a new version is available.",
        "检查是否有新版本可用。",
        "檢查是否有新版本可用。",
    ),
    "Check Now": ("Check Now", "立即检查", "立即檢查"),
    "Update Channel": ("Update Channel", "更新通道", "更新通道"),
    "Stable builds are recommended. Beta builds contain new features but may be unstable.": (
        "Stable builds are recommended. Beta builds contain new features but may be unstable.",
        "建议使用稳定版。测试版包含新功能，但可能不稳定。",
        "建議使用穩定版。測試版包含新功能，但可能不穩定。",
    ),
    "Stable": ("Stable", "稳定版", "穩定版"),
    "Preview": ("Preview", "预览版", "預覽版"),
    # MARK: - 诊断与存储
    "Diagnostics": ("Diagnostics", "诊断日志", "診斷記錄"),
    "Storage": ("Storage", "占用空间", "佔用空間"),
    "%@ uses about %@ of disk space to keep its plugins, preferences, and credentials.": (
        "%1$@ uses about %2$@ of disk space to keep its plugins, preferences, and credentials.",
        "%1$@ 使用约 %2$@ 的磁盘空间来保存插件、偏好设置和凭据。",
        "%1$@ 使用約 %2$@ 的磁碟空間來儲存外掛、偏好設定和憑證。",
    ),
    "Storage service is unavailable.": (
        "Storage service is unavailable.",
        "存储服务暂不可用。",
        "儲存服務暫不可用。",
    ),
    "Calculating...": ("Calculating...", "正在计算…", "正在計算…"),
    "Open": ("Open", "打开", "開啟"),
    # MARK: - 导出日志
    "Export Logs": ("Export Logs", "导出日志", "匯出記錄"),
    "Export logs and diagnostic information for troubleshooting.": (
        "Export logs and diagnostic information for troubleshooting.",
        "导出日志和诊断信息以便排查问题。",
        "匯出記錄和診斷資訊以便排查問題。",
    ),
    "Export": ("Export", "导出", "匯出"),
    "Exporting...": ("Exporting...", "导出中…", "匯出中…"),
    "Choose where to save the diagnostics log": (
        "Choose where to save the diagnostics log",
        "选择诊断日志保存位置",
        "選擇診斷記錄儲存位置",
    ),
    "Export cancelled.": ("Export cancelled.", "已取消导出。", "已取消匯出。"),
    "Logs exported: %@": ("Logs exported: %@", "日志已导出：%@", "記錄已匯出：%@"),
    "Export failed: %@": ("Export failed: %@", "导出失败：%@", "匯出失敗：%@"),
    "Log service is unavailable.": (
        "Log service is unavailable.",
        "日志服务暂不可用。",
        "記錄服務暫不可用。",
    ),
    # MARK: - 卸载
    "Uninstall": ("Uninstall", "卸载", "卸載"),
    "Uninstall %@": ("Uninstall %@", "卸载 %@", "卸載 %@"),
    "Removes all %@ data from your Mac.": (
        "Removes all %@ data from your Mac.",
        "移除本机上的全部 %@ 数据。",
        "移除本機上的全部 %@ 資料。",
    ),
    "This will remove all %@ data from your Mac.": (
        "This will remove all %@ data from your Mac.",
        "这将移除本机上的全部 %@ 数据。",
        "這將移除本機上的全部 %@ 資料。",
    ),
    "Also delete API Keys, passwords, and credentials from Keychain": (
        "Also delete API Keys, passwords, and credentials from Keychain",
        "同时删除 Keychain 中的 API Key、密码和凭据",
        "同時刪除 Keychain 中的 API Key、密碼和憑證",
    ),
    "Also move the %@ app to Trash": (
        "Also move the %@ app to Trash",
        "同时将 %@ 应用移到废纸篓",
        "同時將 %@ 應用程式移到垃圾桶",
    ),
    "Will process %lld items of %@ data, %@ in total.": (
        "Will process %1$lld items of %2$@ data, %3$@ in total.",
        "将处理 %1$lld 项 %2$@ 数据，总计 %3$@。",
        "將處理 %1$lld 項 %2$@ 資料，總計 %3$@。",
    ),
    "%lld more items will be processed after confirmation.": (
        "%lld more items will be processed after confirmation.",
        "还有 %lld 项，将在确认后一起处理。",
        "還有 %lld 項，將在確認後一併處理。",
    ),
    "Cancel": ("Cancel", "取消", "取消"),
    "Uninstalling...": ("Uninstalling...", "卸载中…", "卸載中…"),
    "Uninstalling %@...": ("Uninstalling %@...", "正在卸载 %@…", "正在卸載 %@…"),
    "Permanent Delete and Uninstall": (
        "Permanent Delete and Uninstall",
        "永久删除并卸载",
        "永久刪除並卸載",
    ),
    "Clear Data and Quit": ("Clear Data and Quit", "清除数据并退出", "清除資料並結束"),
    "Uninstall...": ("Uninstall...", "卸载…", "卸載…"),
    "Uninstall service is unavailable.": (
        "Uninstall service is unavailable.",
        "卸载服务暂不可用。",
        "卸載服務暫不可用。",
    ),
    "Uninstall failed: %@": ("Uninstall failed: %@", "卸载失败：%@", "卸載失敗：%@"),
    # MARK: - 卸载浮层
    "This action cannot be undone": ("This action cannot be undone", "此操作无法撤销", "此操作無法撤銷"),
    "Clearing plugin data, preferences, extension data, and credentials.": (
        "Clearing plugin data, preferences, extension data, and credentials.",
        "正在清除插件数据、偏好设置、扩展数据和凭据。",
        "正在清除外掛資料、偏好設定、擴充資料和憑證。",
    ),
    "Uninstall Complete": ("Uninstall Complete", "卸载完成", "卸載完成"),
    "%@ has been removed from your Mac and moved to Trash.": (
        "%@ has been removed from your Mac and moved to Trash.",
        "%@ 已从你的 Mac 移除，应用已移到废纸篓。",
        "%@ 已從你的 Mac 移除，應用程式已移至垃圾桶。",
    ),
    "%@ data has been cleared. The app will now quit.": (
        "%@ data has been cleared. The app will now quit.",
        "%@ 数据已清除，应用即将退出。",
        "%@ 資料已清除，應用程式即將結束。",
    ),
    "s until auto-quit": ("s until auto-quit", "秒后自动退出", "秒後自動結束"),
    "Uninstall Incomplete": ("Uninstall Incomplete", "卸载未完成", "卸載未完成"),
    "Some data could not be cleared. The app was not removed.": (
        "Some data could not be cleared. The app was not removed.",
        "部分数据未能清除，应用未移除。",
        "部分資料未能清除，應用程式未移除。",
    ),
    "Some data could not be cleared. The app was not removed:\n%@": (
        "Some data could not be cleared. The app was not removed:\n%@",
        "部分数据未能清除，应用未移除：\n%@",
        "部分資料未能清除，應用程式未移除：\n%@",
    ),
    "Close": ("Close", "关闭", "關閉"),
    # MARK: - 旧版兼容键（文档示例与历史调用点保留）
    "%lld": ("%lld", "%lld", "%lld"),
    "%lld of %lld": ("%lld of %lld", "%lld / %lld", "%lld / %lld"),
    # MARK: - CLI 安装（Lumi 品牌；Wakey 隐藏该区块但共用同一份文案）
    "Command Line Tool": ("Command Line Tool", "命令行工具", "命令列工具"),
    "Add %@ to your PATH to use the command right away.": (
        "Add %@ to your PATH to use the command right away.",
        "将 %@ 加入 PATH，即可立即使用该命令。",
        "將 %@ 加入 PATH，即可立即使用該命令。",
    ),
    "Install": ("Install", "安装", "安裝"),
    "Install the lumi command to open directories from the terminal.": (
        "Install the lumi command to open directories from the terminal.",
        "安装 lumi 命令，即可在终端中打开目录。",
        "安裝 lumi 命令，即可在終端機中開啟目錄。",
    ),
    "Installed at %@": ("Installed at %@", "已安装到 %@", "已安裝到 %@"),
    "Not Installed": ("Not Installed", "未安装", "未安裝"),
    "The lumi command is ready to use.": (
        "The lumi command is ready to use.",
        "lumi 命令已就绪。",
        "lumi 命令已就緒。",
    ),
    "Installation failed: %@": ("Installation failed: %@", "安装失败：%@", "安裝失敗：%@"),
    "Check...": ("Check...", "检查…", "檢查…"),
    "Checking...": ("Checking...", "正在检查…", "正在檢查…"),
    "Build": ("Build", "构建", "建置"),
    "Name": ("Name", "名称", "名稱"),
    "Lumi": ("Lumi", "Lumi", "Lumi"),
    "Registers the General settings entry with app info, website and updates.": (
        "Registers the General settings entry with app info, website and updates.",
        "在设置视图中注册「通用」入口，包含应用信息、网站与更新。",
        "在設定中註冊「一般」入口，包含應用程式資訊、網站與更新。",
    ),
}

# 旧 catalog 里「中文当 key」的脏条目 + Lumi 专属但已无调用点的条目。
# 这些 key 从未被代码引用（代码用的是英文 key），保留只会让人误以为已翻译。
OBSOLETE_KEYS = {
    "%lld",
    "Bundle ID",
    "Check whether a newer version of Lumi is available.",
    "Lumi 已从你的 Mac 移除，应用已移到废纸篓。",
    "Lumi 数据已清除，应用即将退出。",
    "将处理 %lld 项 Lumi 数据，总计 %@。",
    "使用中",
    "占用空间",
    "卸载完成",
    "卸载未完成",
    "各功能的使用指南。",
    "同时删除 Keychain 中的 API Key、密码和凭据",
    "同时将 Lumi 应用移到废纸篓",
    "导出日志",
    "当前选项不会删除任何项目。",
    "彻底卸载 Lumi",
    "打包最近的运行日志，便于提交问题反馈。",
    "暂时还没有说明书。",
    "更新通道",
    "正在卸载 Lumi…",
    "正在清除插件数据、偏好设置、扩展数据和凭据。",
    "此操作会永久删除 Lumi 自己保存的数据。用户项目、源码和导出的文件不会被删除。",
    "此操作无法撤销",
    "清除 Lumi 的插件数据、偏好设置、扩展数据和可选凭据。",
    "秒后自动退出",
    "稳定版",
    "获取 main 分支发布的稳定版本。",
    "获取 pre 分支发布的预览版本，可能包含未修复的问题。",
    "说明书",
    "还有 %lld 项，将在确认后一起处理。",
    "部分数据未能清除，应用未移除。",
    "预览版",
}

LANGUAGES = ("en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW")


def build() -> dict:
    strings = {}
    for key, (en, hans, hant) in TRANSLATIONS.items():
        if key in OBSOLETE_KEYS and key not in {
            "Bundle ID",
            "%lld",
        }:
            raise SystemExit(f"翻译表与废弃 key 列表冲突：{key!r}")

        values = {"en": en, "zh-Hans": hans, "zh-Hant": hant}
        if hans == hant:
            values["zh-HK"] = hant
            values["zh-TW"] = hant
        else:
            values["zh-HK"] = hant
            values["zh-TW"] = hant

        strings[key] = {
            "localizations": {
                lang: {
                    "stringUnit": {
                        "state": "translated",
                        "value": values[lang],
                    }
                }
                for lang in LANGUAGES
            },
        }
    return strings


def main() -> None:
    data = {
        "sourceLanguage": "en",
        "strings": build(),
        "version": "1.0",
    }
    CATALOG.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {len(data['strings'])} entries to {CATALOG}")


if __name__ == "__main__":
    main()
