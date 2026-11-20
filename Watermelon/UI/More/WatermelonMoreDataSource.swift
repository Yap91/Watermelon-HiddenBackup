//
//  WatermelonMoreDataSource.swift
//  Watermelon
//

import Foundation
import MoreKit
import UIKit

class WatermelonMoreDataSource: MoreViewControllerDataSource {
    private enum ItemID {
        static let pro = "pro"
        static let manageProfiles = "manageProfiles"
        static let storageUsage = "storageUsage"
        static let defaultDeviceScope = "defaultDeviceScope"
        static let workerCount = "workerCount"
        static let iCloudPhotoBackup = "iCloudPhotoBackup"
        static let inboxTransferTutorial = "inboxTransferTutorial"
        static let inboxTransferLivePhotoVideo = "inboxTransferLivePhotoVideo"
        static let inboxTransferOriginalPhoto = "inboxTransferOriginalPhoto"
        static let inboxTransferOriginalVideo = "inboxTransferOriginalVideo"
        static let inboxTransferRemoveLocation = "inboxTransferRemoveLocation"
        static let browserLinkRateLimit = "browserLinkRateLimit"
        static let monthGroupingTimeZone = "monthGroupingTimeZone"
        static let backgroundBackup = "backgroundBackup"
        static let backgroundBackupNodes = "backgroundBackupNodes"
        static let shortcuts = "shortcuts"
        static let language = "language"
        static let photosPermission = "photosPermission"
        static let notificationsPermission = "notificationsPermission"
        static let diagnosticLogs = "diagnosticLogs"
        static let pipProgress = "pipProgress"
        static let pipSound = "pipSound"
        static let magicYapProfile = "magicYapProfile"
        static let versionInfo = "versionInfo"
        static let testCrash = "testCrash"
    }

    private let dependencies: DependencyContainer?
    private let permissions: PermissionSettings
    private let onProfilesChanged: (() -> Void)?
    private let isMonthGroupingTimeZoneChangeBlocked: () -> Bool

    @MainActor
    init(
        dependencies: DependencyContainer?,
        onProfilesChanged: (() -> Void)?,
        isMonthGroupingTimeZoneChangeBlocked: @escaping () -> Bool = { false }
    ) {
        self.dependencies = dependencies
        self.permissions = PermissionSettings()
        self.onProfilesChanged = onProfilesChanged
        self.isMonthGroupingTimeZoneChangeBlocked = isMonthGroupingTimeZoneChangeBlocked
    }

    func sections(for controller: MoreViewController) -> [MoreSectionType] {
        let permissionValues = MainActor.assumeIsolated { (permissions.photosValue, permissions.notificationsValue) }
        // Self-hosted fork: omit the paid membership entry from Settings.
        var sections: [MoreSectionType] = []

        sections.append(.custom(MoreCustomSection(
            id: "general",
            header: String(localized: "more.section.general"),
            items: [
                MoreCustomItem(
                    id: ItemID.language,
                    title: String(localized: "more.item.settings.language"),
                    value: String(localized: "more.item.settings.language.value")
                ),
                MoreCustomItem(
                    id: ItemID.photosPermission,
                    title: String(localized: "settings.permission.photos.title"),
                    value: permissionValues.0
                ),
                MoreCustomItem(
                    id: ItemID.notificationsPermission,
                    title: String(localized: "settings.permission.notifications.title"),
                    value: permissionValues.1
                )
            ]
        )))

        if let dependencies {
            sections.append(.custom(MoreCustomSection(
                id: "remoteStorage",
                header: String(localized: "more.section.remoteStorage"),
                items: [
                    MoreCustomItem(id: ItemID.manageProfiles, title: String(localized: "more.item.manageStorage")),
                ]
            )))
            sections.append(.custom(MoreCustomSection(
                id: "backup",
                header: String(localized: "more.section.backup"),
                items: [
                    MoreCustomItem(
                        id: ItemID.defaultDeviceScope,
                        title: DefaultDeviceMediaScopeSetting.getTitle(),
                        value: LocalDataSourceStore.shared.defaultSource.title
                    ),
                    MoreCustomItem(
                        id: ItemID.workerCount,
                        title: String(localized: "settings.worker.default.title"),
                        value: BackupWorkerCountMode.getValue().getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.iCloudPhotoBackup,
                        title: String(localized: "more.item.iCloudAccess"),
                        value: ICloudPhotoBackupMode.getValue().getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.monthGroupingTimeZone,
                        title: String(localized: "settings.monthGroupingTimeZone.title", defaultValue: "Local Photo Grouping Time Zone"),
                        value: MonthGroupingTimeZoneFormatter.title(for: MonthGroupingTimeZonePreference.current)
                    )
                ]
            )))
            sections.append(.custom(MoreCustomSection(
                id: "browserLink",
                header: String(localized: "link.node.backupToComputer"),
                items: [
                    MoreCustomItem(
                        id: ItemID.browserLinkRateLimit,
                        title: String(localized: "settings.browserLinkRateLimit.header"),
                        value: BrowserLinkRateLimitSetting.getValue().getName()
                    )
                ]
            )))
            let bgEligible = ((try? dependencies.databaseManager.fetchServerProfiles()) ?? [])
                .filter { $0.resolvedStorageType != .externalVolume }
            let bgEnabledCount = bgEligible.filter { $0.backgroundBackupEnabled }.count
            sections.append(.custom(MoreCustomSection(
                id: "backgroundBackup",
                header: String(localized: "more.section.backgroundBackup"),
                items: [
                    MoreCustomItem(
                        id: ItemID.backgroundBackup,
                        title: String(localized: "more.item.backgroundBackup"),
                        value: BackgroundBackupSetting.getValue().getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.backgroundBackupNodes,
                        title: String(localized: "more.item.backgroundBackup.nodes"),
                        value: "\(bgEnabledCount)/\(bgEligible.count)"
                    )
                ]
            )))
            if #available(iOS 27.0, *) {
                sections.append(.custom(MoreCustomSection(
                    id: "shortcuts",
                    header: String(localized: "more.section.shortcuts"),
                    footer: ShortcutsSetting.sectionFooter,
                    items: [
                        MoreCustomItem(
                            id: ItemID.shortcuts,
                            title: ShortcutsSetting.getTitle(),
                            value: ShortcutsSetting.displayValue
                        )
                    ]
                )))
            }
            let isPiPProgressActive = PiPProgressSetting.getValue() == .enable
                && MainActor.assumeIsolated { ProStatus.isPro }
            var pipItems = [
                MoreCustomItem(
                    id: ItemID.pipProgress,
                    title: String(localized: "more.item.pipProgress"),
                    value: PiPProgressSetting.getValue().getName()
                )
            ]
            if isPiPProgressActive {
                pipItems.append(MoreCustomItem(
                    id: ItemID.pipSound,
                    title: String(localized: "settings.pipSound.header"),
                    value: PiPProgressSoundSetting.getValue().getName()
                ))
            }
            sections.append(.custom(MoreCustomSection(
                id: "pip",
                header: String(localized: "more.section.pip"),
                items: pipItems
            )))
            sections.append(.custom(MoreCustomSection(
                id: "transfer",
                header: String(localized: "transfer.settings.title"),
                items: [
                    MoreCustomItem(
                        id: ItemID.inboxTransferTutorial,
                        title: String(localized: "transfer.settings.tutorial")
                    ),
                    MoreCustomItem(
                        id: ItemID.inboxTransferLivePhotoVideo,
                        title: InboxTransferLivePhotoVideoSetting.getTitle(),
                        value: InboxTransferLivePhotoVideoSetting.current.getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.inboxTransferOriginalPhoto,
                        title: InboxTransferOriginalPhotoSetting.getTitle(),
                        value: InboxTransferOriginalPhotoSetting.current.getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.inboxTransferOriginalVideo,
                        title: InboxTransferOriginalVideoSetting.getTitle(),
                        value: InboxTransferOriginalVideoSetting.current.getName()
                    ),
                    MoreCustomItem(
                        id: ItemID.inboxTransferRemoveLocation,
                        title: InboxTransferRemoveLocationSetting.getTitle(),
                        value: InboxTransferRemoveLocationSetting.current.getName()
                    ),
                ]
            )))
            sections.append(.custom(MoreCustomSection(
                id: "storageUsage",
                header: String(localized: "more.item.storageUsage"),
                items: [
                    MoreCustomItem(id: ItemID.storageUsage, title: String(localized: "more.item.storageUsage")),
                ]
            )))
        }

        sections.append(.custom(MoreCustomSection(
            id: "magicYapAbout",
            header: "关于",
            items: [
                MoreCustomItem(
                    id: ItemID.magicYapProfile,
                    title: "Magic Yap",
                    showsDisclosureIndicator: false
                ),
                MoreCustomItem(
                    id: ItemID.versionInfo,
                    title: "版本信息",
                    value: versionInformation,
                    showsDisclosureIndicator: false
                )
            ]
        )))

        var diagnosticsItems: [MoreCustomItem] = [
            MoreCustomItem(
                id: ItemID.diagnosticLogs,
                title: String(localized: "more.item.diagnosticLogs")
            )
        ]
        #if DEBUG
        diagnosticsItems.append(
            MoreCustomItem(id: ItemID.testCrash, title: "Test Crash (Debug)")
        )
        #endif
        sections.append(.custom(MoreCustomSection(
            id: "diagnostics",
            header: String(localized: "more.section.diagnostics"),
            items: diagnosticsItems
        )))

        return sections
    }

    func additionalReloadNotifications() -> [Notification.Name] {
        [.BackgroundBackupProfileChanged, .ProfileListChanged, .MonthGroupingTimeZonePreferenceDidChange]
    }

    func moreViewController(_ controller: MoreViewController, didSelectCustomItem item: MoreCustomItem) {
        MainActor.assumeIsolated {
            switch item.id {
            case ItemID.pro:
                controller.presentWatermelonPaywall()
            case ItemID.manageProfiles:
                guard let dependencies else { return }
                let vc = ManageStorageProfilesViewController(dependencies: dependencies) { [weak self] in
                    self?.onProfilesChanged?()
                    NotificationCenter.default.post(name: .ProfileListChanged, object: nil)
                }
                controller.pushViewController(vc)
            case ItemID.storageUsage:
                controller.pushViewController(StorageUsageViewController())
            case ItemID.workerCount:
                controller.enterSettings(BackupWorkerCountMode.self)
            case ItemID.defaultDeviceScope:
                guard let dependencies else { return }
                controller.pushViewController(DefaultDataSourceViewController(service: dependencies.photoLibraryService))
            case ItemID.iCloudPhotoBackup:
                controller.enterSettings(ICloudPhotoBackupMode.self)
            case ItemID.inboxTransferTutorial:
                let tutorial = MediaDropTutorialViewController(allowsDismissal: true)
                let container = AppNavigationController(rootViewController: tutorial)
                if let sheet = container.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = true
                }
                tutorial.onCompleted = { [weak container] in
                    MediaDropTutorialViewController.CompletionGate.markCompleted()
                    container?.dismiss(animated: ConsideringUser.animated)
                }
                controller.present(container, animated: ConsideringUser.animated)
            case ItemID.inboxTransferLivePhotoVideo:
                controller.enterSettings(InboxTransferLivePhotoVideoSetting.self)
            case ItemID.inboxTransferOriginalPhoto:
                controller.enterSettings(InboxTransferOriginalPhotoSetting.self)
            case ItemID.inboxTransferOriginalVideo:
                controller.enterSettings(InboxTransferOriginalVideoSetting.self)
            case ItemID.inboxTransferRemoveLocation:
                controller.enterSettings(InboxTransferRemoveLocationSetting.self)
            case ItemID.browserLinkRateLimit:
                controller.enterSettings(BrowserLinkRateLimitSetting.self)
            case ItemID.monthGroupingTimeZone:
                let isMonthGroupingTimeZoneChangeBlocked = isMonthGroupingTimeZoneChangeBlocked
                controller.pushViewController(MonthGroupingTimeZoneSettingsViewController(
                    canChangePreference: { !isMonthGroupingTimeZoneChangeBlocked() }
                ))
            case ItemID.backgroundBackup:
                controller.enterSettings(BackgroundBackupSetting.self)
            case ItemID.shortcuts:
                controller.enterSettings(ShortcutsSetting.self)
            case ItemID.backgroundBackupNodes:
                guard let dependencies else { return }
                let vc = BackgroundBackupNodesViewController(dependencies: dependencies) { [weak self] in
                    self?.onProfilesChanged?()
                    NotificationCenter.default.post(name: .ProfileListChanged, object: nil)
                }
                controller.pushViewController(vc)
            case ItemID.pipProgress:
                controller.enterSettings(PiPProgressSetting.self)
            case ItemID.pipSound:
                controller.enterSettings(PiPProgressSoundSetting.self)
            case ItemID.language:
                controller.jumpToSettings()
            case ItemID.photosPermission:
                Task { await permissions.openPhotos() }
            case ItemID.notificationsPermission:
                Task { await permissions.openNotifications(from: controller) }
            case ItemID.diagnosticLogs:
                controller.pushViewController(ExecutionLogHistoryViewController())
            #if DEBUG
            case ItemID.testCrash:
                fatalError("Test crash for Crashlytics activation")
            #endif
            default:
                break
            }
        }
    }


    func moreViewController(_ controller: MoreViewController, cellFor item: MoreCustomItem) -> UITableViewCell? {
        MainActor.assumeIsolated {
            switch item.id {
            case ItemID.magicYapProfile:
                return MagicYapProfileCell()
            case ItemID.versionInfo:
                return MagicYapVersionCell(value: item.value ?? "")
            case ItemID.pro:
                return WatermelonProEntryCell(isPro: ProStatus.isPro) { [weak controller] in
                    controller?.presentWatermelonPaywall()
                }
            default:
                return nil
            }
        }
    }

    private var versionInformation: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        var details = ["基于西瓜开源修改"]
        if let shortVersion, !shortVersion.isEmpty {
            details.append(shortVersion)
        }
        if let build, !build.isEmpty, build != shortVersion {
            details.append("(\(build))")
        }
        return details.joined(separator: " · ")
    }
}

private final class MagicYapProfileCell: UITableViewCell {
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        overrideUserInterfaceStyle = .dark
        backgroundColor = .secondarySystemGroupedBackground
        accessoryType = .none
        selectionStyle = .none

        let avatarView = UIImageView(image: UIImage(named: "MagicYapAvatar"))
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 32
        avatarView.isAccessibilityElement = false

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Magic Yap"
        nameLabel.textColor = .white
        nameLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 23, weight: .semibold)
        )
        nameLabel.adjustsFontForContentSizeCategory = true

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            avatarView.widthAnchor.constraint(equalToConstant: 64),
            avatarView.heightAnchor.constraint(equalToConstant: 64),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Magic Yap"
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MagicYapVersionCell: UITableViewCell {
    init(value: String) {
        super.init(style: .value1, reuseIdentifier: nil)
        overrideUserInterfaceStyle = .dark
        backgroundColor = .secondarySystemGroupedBackground
        accessoryType = .none
        selectionStyle = .none

        var content = UIListContentConfiguration.valueCell()
        content.text = "版本信息"
        content.textProperties.color = .white
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.secondaryText = value
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        contentConfiguration = content

        isAccessibilityElement = true
        accessibilityLabel = "版本信息，\(value)"
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
