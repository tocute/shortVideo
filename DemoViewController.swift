//
//  DemoViewController.swift
//  TripleDotsSDK
//
//  Created by Mike Chou on 2020/11/3.
//  Copyright © 2020 Yahoo. All rights reserved.
//

import UIKit
import VerizonMediaTripleDots
import SDWebImage
import AppDevKit
import MangoSDK
import MobileCoreServices
//import YAppManagement
import Photos

public protocol DemoViewControllerDelegate: AnyObject {
    func demoViewController(_ viewController: DemoViewController, didUpdateUnreadCount count: Int, unreadInfo: [TDSChannelType: Int])
    func demoViewController(_ viewController: DemoViewController, didUpdateTopBannerType type: TDSTopBannerType)
    func demoViewController(_ viewController: DemoViewController, didUpdateServiceConfig config: TDSServiceConfig)
    func demoViewController(_ viewController: DemoViewController, didWantToDisplayHomapage shouldDisplay: Bool)
}

public class DemoViewController: UIViewController {

    enum Constants {
        static let kTableViewCellDefaultIdentifier: String = "DefaultCell"
        static let kSquareImage: String = "https://s.yimg.com/vi/api/res/1.2/SrDbrbpkmUeFeA31HaiUbw--~A/YXBwaWQ9eXR3ZWNvbW1lcmNlO2g9NDAwO3c9NDAw/https://s.yimg.com/pk/thumbnail/5a6fea2cc268baf9683bf3d16d6f3a70775aaf47.jpg"
        static let kSquareImageSpec: TDSMediaSpec = TDSMediaSpec(width: 400, height: 400, url: URL(string: kSquareImage))
        static let kRectImage: String = "https://s.yimg.com/xd/api/res/1.2/uBZSA8s9WUNJIXDK1vQDaw--/YXBwaWQ9eXR3YXVjdGlvbnNlcnZpY2U7aD0zMDA7cT04NTtyb3RhdGU9YXV0bzt3PTQwMA--/https://s.yimg.com/ma/26d8/mapi/3af2ce7e-ed0e-4b3e-8052-254dd43306f3.png"
        static let kRectImageSpec: TDSMediaSpec = TDSMediaSpec(width: 400, height: 300, url: URL(string: kRectImage))
        fileprivate static let customAvailableFeelings: [TDSChannelFeeling] = [
            TDSChannelFeeling(index: 1, name: "讚", url: Bundle.main.url(forResource: "thumbsup", withExtension: "png")?.absoluteString)!,
            TDSChannelFeeling(index: 2, name: "愛心", url: Bundle.main.url(forResource: "heart", withExtension: "png")?.absoluteString)!,
            TDSChannelFeeling(index: 3, name: "笑死", url: Bundle.main.url(forResource: "laugh", withExtension: "png")?.absoluteString)!,
            TDSChannelFeeling(index: 4, name: "驚訝", url: Bundle.main.url(forResource: "surprise", withExtension: "png")?.absoluteString)!]
        static let jomaMockGroupChannelId: String = "mockGroupChannel001"
    }

    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var propertySegControl: UISegmentedControl!
    @IBOutlet weak var themeSegControl: UISegmentedControl!
    @IBOutlet weak var environmentSegControl: UISegmentedControl!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var prescrollSegControl: UISegmentedControl!

    public weak var delegate: DemoViewControllerDelegate?

    var service: TDSServiceManager = TDSServiceManager.shared
    var currentProperty: TDSProperty
    var currentEnvironment: TDSEnvironment

    var customizedInputBroadcastHostVC: TDSMessagingViewController?
    var hasSubscribedCustomizedBroadcastHost: Bool = false
    var hasFetchedChannelFilteredList: Bool = false
    var hasDisplayInputOptionFeatureCue: Bool = false

    private var showCases: [[[String]]]?
    private var apiCases: [[String]]?

    private(set) var shouldAutoFocusWelcomeMenu: Bool = false
    private var shouldDisplayHomepageTab: Bool = false
    private var shouldRefreshCookies: Bool = false

    var visibleViewController: UIViewController {
        return self.getVisibleViewController(self.tds_topViewController)
    }
    weak var channelActionInteractiveVC: (UIViewController & TDSMessagingViewControllerProtocol)?

    private var channelIdFromEditor: String?
    private var counterPeerId: String? {
        // Prod:
        //   qe8: Y7991780710
        //   qe9: Y5465823204
        //   qe34:Y5214725481
        //   qe24:Y6496812825
        // Beta:
        //   qe8: Y5686945627
        //   qe9: Y1130756086
        //   qe34:Y2447054057

        let yid = DemoAccountManager.shared.yid
        if yid == "yqa_tw_ios_qe8" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "Y5465823204"
            }
            return "Y1130756086"
        } else if yid == "yqa_tw_ios_qe9" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "Y7991780710"
            }
            return "Y5686945627"
        } else if yid == "yqa_tw_api_qe34" || yid == "yqa_tw_api_qe35" {
            #if YBUILD_AUTOMATIONTEST
            // qe34 could chat with qe24 in UITests
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "Y6496812825"
            }
            #endif
        } /* else if yid == "tw_auc_user3",
                  DemoAPIClient.shared.enviroment == .devel,
                  self.currentProperty == .twMall {
            return "5ZD036FF34A21E4838BB5F00FB951064EC"
        } */

        self.tds_showAlert(title: "請用 yqa_tw_ios_qe8 或 yqa_tw_ios_qe9 登入")
        return nil
    }

    public var broadcastChannelId: String? {
        // Prod:
        //   qe8: ddd98e27-72d9-4388-89d3-8e88420b8125
        //   qe9: 0a775aa7-8699-4863-9828-8b7d4fbe2a2f
        //   qe34: 6f601955-83a0-49ac-96d4-7e0685faea3d
        // Beta:
        //   qe8: not enable
        //   qe9: not enable
        //   qe34: baf87ccb-7113-4ff9-94ca-2597e39fd2b1

        let yid = DemoAccountManager.shared.yid
        if yid == "yqa_tw_ios_qe8" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "ddd98e27-72d9-4388-89d3-8e88420b8125"
            }
        } else if yid == "yqa_tw_ios_qe9" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "0a775aa7-8699-4863-9828-8b7d4fbe2a2f"
            }
        } else if yid == "yqa_tw_api_qe34" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "6f601955-83a0-49ac-96d4-7e0685faea3d"
            }
            #if YBUILD_AUTOMATIONTEST
            #else
            self.tds_showAlert(title: "qe34 beta 粉絲通頻道僅供 UITests 使用, 請謹慎操作")
            #endif
            return "baf87ccb-7113-4ff9-94ca-2597e39fd2b1"
        } else if yid == "yqa_tw_api_qe35" {
            if self.environmentSegControl.selectedSegmentIndex == 0 {
                return "8c62c19f-9a49-43a2-9f09-d675e9046a4f"
            }
            self.tds_showAlert(title: "qe35 尚未開啟 beta 權限")
            return nil
        } else {
            self.tds_showAlert(title: "請用 yqa_tw_ios_qe8 或 yqa_tw_ios_qe9 或 yqa_tw_api_qe34 或 yqa_tw_api_qe35 登入")
            return nil
        }

        self.tds_showAlert(title: "該帳號在此環境未開啟粉絲通")
        return nil
    }

    public var activityChannelId: String {
        // Prod:
        //   32671f4f-0891-4439-8ad8-c3d62b62a8c3
        // Beta:
        //   c42c3865-4661-4282-b791-9590033c39b3

        if self.environmentSegControl.selectedSegmentIndex == 0 {
            return "32671f4f-0891-4439-8ad8-c3d62b62a8c3"
        }
        return "c42c3865-4661-4282-b791-9590033c39b3"
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    init(with property: TDSProperty, environment: TDSEnvironment) {
        self.currentProperty = property
        self.currentEnvironment = environment
        super.init(nibName: "DemoViewController", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        #if YBUILD_AUTOMATIONTEST
        if ProcessInfo.processInfo.arguments.contains("--MonkeyTest") {
            self.environmentSegControl.selectedSegmentIndex = 1
        }
        #endif

        TDSServiceManager.shared.userAgent = DemoAPIClient.userAgent
        // TODO: Bill
//        YMConfigManager.registerSdk(TDSServiceManager.sdkName, majorVersion: 1, minorVersion: 0, patchVersion: 0)

        // NOTE: only light theme for now.
        self.overrideUserInterfaceStyle = .light
        self.environmentSegControl.selectedSegmentIndex = 0
        if let propertyIndex = self.propertyToIndex(self.currentProperty) {
            self.propertySegControl.selectedSegmentIndex = propertyIndex - 1
        } else {
            self.propertySegControl.selectedSegmentIndex = 0
        }

        let environmentSegIndex = 0
        self.environmentSegControl.selectedSegmentIndex = environmentSegIndex

        self.setupNotifications()
        self.setupCustomMessages()
        self.setupShowCases()
        self.setupService()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.kTableViewCellDefaultIdentifier)
    }

    private func getVisibleViewController(_ rootViewController: UIViewController) -> UIViewController {
            if let presentedViewController = rootViewController.presentedViewController {
                return self.getVisibleViewController(presentedViewController)

            } else if let navigationController = rootViewController as? UINavigationController,
                      let visibleViewController = navigationController.visibleViewController {
                return self.getVisibleViewController(visibleViewController)

            } else if let tabBarController = rootViewController as? UITabBarController,
                      let selectedViewController = tabBarController.selectedViewController {
                return self.getVisibleViewController(selectedViewController)
            }
            return rootViewController
        }
}

// MARK: UI Action handler
extension DemoViewController {

    @IBAction func connect(_ sender: AnyObject) {
        self.view.ymg_startLoadingAnimation()
        self.service.connect { [weak self] (error) in
            guard let strongSelf = self else { return }
            strongSelf.view.ymg_stopLoadingAnimation()
            if let aError = error {
                let message = aError is TDSError ? (aError as? TDSError)?.errorDescription : aError.localizedDescription
                strongSelf.tds_showAlert(title: "Connect Fail", message: message)
            }
        }
    }

    @IBAction func disconnect(_ sender: AnyObject) {
        self.service.disconnect()
    }

    @IBAction func manageAccount(_ sender: AnyObject) {
        DemoAccountManager.shared.signIn(with: self)
    }

    @IBAction func manageOptions(_ sender: AnyObject) {
        let carouselAction = UIAlertAction(title: "\(self.shouldDisplayHomepageTab ? "Disable" : "Enable") homepage tab", style: .default, handler: { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.shouldDisplayHomepageTab = !strongSelf.shouldDisplayHomepageTab
            strongSelf.delegate?.demoViewController(strongSelf, didWantToDisplayHomapage: strongSelf.shouldDisplayHomepageTab)
        })
        let welcomeAction = UIAlertAction(title: "\(self.shouldAutoFocusWelcomeMenu ? "Disable" : "Enable") welcome menu focus", style: .default, handler: { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.shouldAutoFocusWelcomeMenu = !strongSelf.shouldAutoFocusWelcomeMenu
        })
        let bannerAction = UIAlertAction(title: "Switch Top Banner Style", style: .default, handler: { [weak self] (action) in
            self?.presentChangeTopBannerAlert()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        var actions = [carouselAction, welcomeAction, bannerAction, cancelAction]

        if let userId = self.service.currentUserId,
           userId.isEmpty == false {
            let resetAction = UIAlertAction(title: "Reset \(userId) preference", style: .default) { (action) in
                TDSUserDefaultManager.reset(for: userId)
            }
            actions.insert(resetAction, at: 0)
        }

        if TDSAccountManager.shared.passportToken == nil {
            let loginAction = UIAlertAction(title: "B2B login", style: .default) { [weak self] (action) in
                self?.b2bLogin(action)
            }
            actions.append(loginAction)
        }
        let logoutAction = UIAlertAction(title: "B2B logout (or purge cache)", style: .default) { [weak self] (action) in
            self?.b2bLogout(action)
        }
        actions.append(logoutAction)

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.accessibilityIdentifier = "demoOptionsSheet"
        for action in actions {
            alertController.addAction(action)
        }
        // swiftlint:disable use_tds_present
        self.present(alertController, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func didChangeProperty(_ sender: AnyObject) {
        guard let property = self.propertyFromIndex(self.propertySegControl.selectedSegmentIndex + 1) else { return }
        self.shouldRefreshCookies = true
        self.currentProperty = property
        self.tableView.reloadData()
        self.setupService()
    }

    @IBAction func didChangeEnvironment(_ sender: AnyObject) {
        if TDSAccountManager.shared.passportToken != nil || DemoAccountManager.shared.isB2BLogIn {
            self.b2bLogout(sender)
        }
        self.shouldRefreshCookies = true
        self.currentEnvironment = .production
        self.setupService()
    }
}

// MARK: misc
extension DemoViewController {

    func presentChangeTopBannerAlert() {
        let carouselAction = UIAlertAction(title: "Carousel", style: .default, handler: { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.demoViewController(strongSelf, didUpdateTopBannerType: .carousel)
        })
        let customAction = UIAlertAction(title: "Custom", style: .default, handler: { [weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.demoViewController(strongSelf, didUpdateTopBannerType: .custom)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let actions = [carouselAction, customAction, cancelAction]

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.accessibilityIdentifier = "demoBannerSheet"
        for action in actions {
            alertController.addAction(action)
        }
        // swiftlint:disable use_tds_present
        self.present(alertController, animated: true, completion: nil)
        // swiftlint:enable:previous

    }

    func makeMockEventLotteryMessage(with eventId: String) -> TDSMessageCollection {
        let meta = TDSEventMeta(with: eventId, type: .lottery)
        let spec = Constants.kSquareImageSpec
        let image = TDSImage(thumbnail: spec, src: spec, origin: spec)
        // block link should align to BE regex: https:\/\/(.+.yahoo.com|yauctionuniversity.tumblr.com).+
        let block = TDSMessageInnerBlock(link: "https://tw.search.yahoo.com/search?p=macbook+pro", image: image, id: "mockId")
        let message = TDSMessageCollection(title: "Test Lottery", blocks: [block], theme: "1", event: meta)
        return message
    }

    func propertyToIndex(_ property: TDSProperty) -> Int? {
        switch property {
        case .twAuction:
            return 1
        case .twSuper:
            return 2
        case .twStock:
            return 3
        case .twMall:
            return 4
        case .twBus:
            return 5
        // case .custom:
        case .twShopping:
            return 6
        default:
            return nil
        }
    }

    func propertyFromIndex(_ index: Int) -> TDSProperty? {
        switch index {
        case 1:
            return .twAuction
        case 2:
            return .twSuper
        case 3:
            return .twStock
        case 4:
            return .twMall
        case 5:
            return .twBus
        case 6:
            // return .custom
            return .twShopping
        default:
            return nil
        }
    }
}

// MARK: Private functions
extension DemoViewController {
    private func setupCustomMessages() {
        self.service.setupSearchOrder { (messageTypes) -> ([String])? in
            let orderList = ["text", "listing", "order", "image", "video"]
            let orderedKeys = messageTypes.keys
            return orderedKeys.sorted { (obj1, obj2) -> Bool in
                let obj1Index = orderList.firstIndex(of: obj1) ?? NSNotFound
                let obj2Index = orderList.firstIndex(of: obj2) ?? NSNotFound
                return obj1Index < obj2Index
            }
        }
    }

    private func setupShowCases() {
        let auctionCases = [["Chat with preScrollConfig (qe8 or qe9)", NSStringFromSelector(#selector(showChat(_:)))],
                            ["Chat with listing preview", NSStringFromSelector(#selector(showChatWithListingPreview(_:)))],
                            ["Chat with order preview", NSStringFromSelector(#selector(showChatWithOrderPreview(_:)))],
                            ["Chat with campaign preview", NSStringFromSelector(#selector(showChatWithCampaignPreview(_:)))],
                            ["Chat with broadcast preview", NSStringFromSelector(#selector(showChatWithBroadcastPreview(_:)))],
                            ["Chat with mock lottery event (qe34)", NSStringFromSelector(#selector(showChatWithExpiredLotteryEvent(_:)))],
                            ["Broadcast Channel", NSStringFromSelector(#selector(showBroadcastChannel(_:)))],
                            ["Show video view", NSStringFromSelector(#selector(showVideoView(_:)))],
                            ["Show video view controller", NSStringFromSelector(#selector(showVideoViewController(_:)))]]
        let shoppingCases = [["Show `dovetest` channel with aliasId", NSStringFromSelector(#selector(showDoveTestByAliasId(_:)))],
                             ["Show `dovetest` channel with channelId", NSStringFromSelector(#selector(showDoveTestByChannelId(_:)))],
                             ["Show `wacoal` channel with aliasId", NSStringFromSelector(#selector(showWacoalTestByAliasId(_:)))],
                             ["Select image to upload to pixelFrame", NSStringFromSelector(#selector(selectImageToUpload(_:)))],
                             ["Select video to upload to pixelFrame", NSStringFromSelector(#selector(selectVideoToUpload(_:)))]]

        self.showCases = [auctionCases, shoppingCases]

        self.apiCases = [["Query entity by aliasId", NSStringFromSelector(#selector(queryEntityByAliasId(_:)))]]
    }

    // swiftlint:disable function_body_length
    private func setupService(property: TDSProperty? = nil, environment: TDSEnvironment? = nil) {
        DemoAPIClient.shared.enviroment = .prod
        let aProperty: TDSProperty = property ?? self.currentProperty
        let aEnvironment: TDSEnvironment = environment ?? self.currentEnvironment

        var type: TDSThemeType
        switch aProperty {
        case .twSuper:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .media : .mediaDark
        case .twStock:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .stock : .stockDark
        case .twMall:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .store : .storeDark
        case .twBus:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .bus : .busDark
        case .twShopping:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .shp : .shpDark
        default:
            type = self.themeSegControl.selectedSegmentIndex == 0 ? .auction : .auctionDark
        }
        let config = TDSServiceConfig(property: aProperty, environment: aEnvironment, themeType: type)

        // swiftlint:disable no_use_tdsr
        switch aProperty {
        case .custom:
            break
//            self.service.tdsr_inject(channelDataStoreInitBlock: { (criteria) in
//                return JMChannelDataStore(with: TDSChannelCriteria())
//            }, channelInfoAggregatorInitBlock: { (channel) in
//                    if let channel = channel as? TDSChannel {
//                        return JMChannelInfoAggregator(channel: channel)
//                    }
//                    return JMChannelInfoAggregator(channelId: channel as? String ?? "")
//            }, channelInfoAggregatorPeerInitBlock: { (peerId) in
//                return JMChannelInfoAggregator(peerId: peerId)
//            }, userDataStore: JMUserDataStore(), userIdHelper: JMUserIdHelper(), messageHelper: JMPartnerMessageHelper(), channelTypeMapper: [.single: .single, .group: .customTeam, .activity: .customActivity])
        default:
            // NOTE: Reset from custom inject
            // swiftlint:disable use_svcmgr_channelInfoInit use_svcmgr_channelDataStoreInit
            #if YBUILD_AUTOMATIONTEST
            var mockMessageHelper: DemoMockPartnerMessageHelper?
            if let mockData = ProcessInfo.processInfo.environment["mockMessages"] {
                let messageHelper: DemoMockPartnerMessageHelper? = {
                    guard let jsonData = mockData.data(using: .utf8),
                          let mockDataDict = try? JSONDecoder().decode(TDSMockMessagesResult.self, from: jsonData) else { return nil }
                    let messageHelper = DemoMockPartnerMessageHelper(messagesResult: mockDataDict)
                    return messageHelper
                }()
                mockMessageHelper = messageHelper
            }
            self.service.tdsr_inject(channelDataStoreInitBlock: { (criteria) in
                return TDSChannelDataStore(with: criteria ?? TDSChannelCriteria())
            }, channelInfoAggregatorInitBlock: { (channel) in
                    if let channel = channel as? TDSChannel {
                        return TDSChannelInfoAggregator(channel: channel)
                    }
                    return TDSChannelInfoAggregator(channelId: channel as? String ?? "")
            }, channelInfoAggregatorPeerInitBlock: { (peerId) in
                return TDSChannelInfoAggregator(peerId: peerId)
            }, userDataStore: TDSUserDataStore(), userIdHelper: TDSUserIdHelper(), messageHelper: mockMessageHelper)
            #else
            self.service.tdsr_inject(channelDataStoreInitBlock: { (criteria) in
                return TDSChannelDataStore(with: criteria ?? TDSChannelCriteria())
            }, channelInfoAggregatorInitBlock: { (channel) in
                    if let channel = channel as? TDSChannel {
                        return TDSChannelInfoAggregator(channel: channel)
                    }
                    return TDSChannelInfoAggregator(channelId: channel as? String ?? "")
            }, channelInfoAggregatorPeerInitBlock: { (peerId) in
                return TDSChannelInfoAggregator(peerId: peerId)
            }, userDataStore: TDSUserDataStore(), userIdHelper: TDSUserIdHelper())
            #endif
            // swiftlint:enable:previous
        }
        // swiftlint:enable:previous

        switch aProperty {
        case .twAuction:
            // NOTE: left the fourth emoji as an empty string for backward compatibility to let emoji use the same data as before
            config.searchBarPlaceholder = "搜尋訊息、商品、訂單編號"
            config.shouldShowGoToAnalyticsPanelButton = true

        case .twStock:
            config.messageGroupingIntervalInSecond = Double(60)
            let symbolStyle: TDSTextStyle = TDSTextStyle(name: TDSMessageTextToken.symbolStyleKey,
                                                         textColor: .ymgSky,
                                                         backgroundColor: .clear,
                                                         fontWeight: .regular)
            let changeUpLimitStyle = TDSTextStyle(name: "changeUpLimit",
                                                  textColor: .white,
                                                  backgroundColor: .ymgSoloCup,
                                                  fontWeight: .regular)
            let changeUpStyle = TDSTextStyle(name: "changeUp",
                                             textColor: .ymgWatermelon,
                                             backgroundColor: .clear,
                                             fontWeight: .regular)
            let changeDownLimitStyle = TDSTextStyle(name: "changeDownLimit",
                                                    textColor: .white,
                                                    backgroundColor: .ymgSoloCup,
                                                    fontWeight: .regular)
            let changeDownStyle = TDSTextStyle(name: "changeDown",
                                               textColor: .ymgMulah,
                                               backgroundColor: .clear,
                                               fontWeight: .regular)
            let changeEvenStyle = TDSTextStyle(name: "changeEven",
                                               textColor: .ymgGreyHair,
                                               backgroundColor: .clear,
                                               fontWeight: .regular)
            config.tokenStyles = [symbolStyle.name: symbolStyle,
                                  changeUpLimitStyle.name: changeUpLimitStyle,
                                  changeUpStyle.name: changeUpStyle,
                                  changeDownLimitStyle.name: changeDownLimitStyle,
                                  changeDownStyle.name: changeDownStyle,
                                  changeEvenStyle.name: changeEvenStyle]
            config.canUseStickers = false

        case .custom:
            config.availableFeelings = Constants.customAvailableFeelings
            config.canBanMember = false
            config.canReportMessage = false
            config.canPinMessage = false

//            self.getJomaEnviromentParameters { (token, userId, brandId, domain) in
//                guard let token = token,
//                      let userId = userId,
//                      let brandId = brandId,
//                      let domain = domain else {
//                    assertionFailure("get Joma enviroment parameters failed.")
//                    return
//                }
//                TDSAccountManager.shared.switchToExternalAccount(userId: userId, partnerToken: token, brand: brandId, domain: domain)
//            }
        default:
            break
        }

        config.customUrlSession = AppDelegate.mockUrlSession
        DemoAccountManager.shared.setupB2BConfig(enviroment: aEnvironment, property: aProperty)
        self.service.setup(with: config, delegate: self, dataSource: self, trackingDelegate: self, trackingDataSource: self)
        self.delegate?.demoViewController(self, didUpdateServiceConfig: config)
        if self.shouldRefreshCookies && DemoAccountManager.shared.isLoggedIn {
            DemoAccountManager.shared.refreshCookies(completion: { refreshCookies, error in
                if let guid = DemoAccountManager.shared.guid,
                   let refreshCookies = refreshCookies {
                    TDSAccountManager.shared.yahooAccount = TDSAccount(cookies: refreshCookies, id: guid)
                } else {
                    TDSAccountManager.shared.yahooAccount = nil
                }
            })
        }
        if DemoAccountManager.shared.isB2BLogIn {
            DemoAccountManager.shared.refreshB2BToken { err, passportToken in
                guard let passportToken = passportToken else { return }
                TDSAccountManager.shared.passportToken = passportToken
            }
        }
    }
    // swiftlint:enable:previous
}

// MARK: Auction cases
extension DemoViewController {
    func showChatWithPreviewMessage(message: TDSMessageProtocol?, preScrollConfig: TDSMessageScrollConfig? = nil) {
        guard let counterPeerId = self.counterPeerId else { return }
        guard let vc = TDSFactory.makeMessagingViewController(with: message, peerId: counterPeerId) else {
            self.tds_showAlert(title: "Unable to makeMessagingViewController", message: "peerId = \(counterPeerId)")
            return
        }
        vc.preScrollConfig = preScrollConfig
        vc.delegate = self
        vc.dataSource = self
        let navVC = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navVC, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    func pushToPrivateChat(from viewController: UIViewController, with message: TDSMessageProtocol?) {
        guard let messagingViewController = viewController as? TDSMessagingViewController,
              let peerId = messagingViewController.creatorId,
              let vc = TDSFactory.makeMessagingViewController(with: message, peerId: peerId),
              let navigationController = viewController.navigationController else {
                  self.tds_showAlert(title: "Unable to private chat from viewController:\(viewController)", message: "message: \(String(describing: message?.shortDescription))")
            return
        }
        vc.delegate = self
        vc.dataSource = self
        navigationController.pushViewController(vc, animated: true)
    }

    @IBAction func showChat(_ sender: AnyObject) {
        let index = self.prescrollSegControl.selectedSegmentIndex
        let config = TDSMessageScrollConfig()
        switch index {
        case 1:
            config.position = .firstUnread
        case 2:
            config.position = .specificMessage
            config.messageBottomOffsetPercentage = 0.7
            config.messageId = "27844538-d725-11ec-9b05-75f31f0d56d9"
        default:
            config.position = .latest
        }
        self.showChatWithPreviewMessage(message: nil, preScrollConfig: config)
    }

    @IBAction func showChatWithListingPreview(_ sender: AnyObject) {
        let spec = Constants.kRectImageSpec
        let image = TDSImage(thumbnail: spec, src: spec, origin: spec)
        let listing = TDSMessageListing(id: "100441390510", title: "測試商品 請勿下標", price: "$10", type: "1", images: [image])
        self.showChatWithPreviewMessage(message: listing)
    }

    @IBAction func showChatWithOrderPreview(_ sender: AnyObject) {
        let yid = DemoAccountManager.shared.yid
        let role: TDSOrderUserRole = yid == "yqa_tw_api_qe9" ? .seller : .buyer
        let orderId: String = {
//            guard DemoAPIClient.shared.enviroment == .devel,
//                  self.currentProperty == .twMall else {
//                return "10001023070676"
//            }
            return "501098797"
        }()
        let order = TDSMessageOrder(id: orderId, role: role)
        self.showChatWithPreviewMessage(message: order)
    }

    @IBAction func showChatWithCampaignPreview(_ sender: AnyObject) {
        let campaign = TDSMessageCampaign(groupId: "53841", type: "coupon")
        self.showChatWithPreviewMessage(message: campaign)
    }

    @IBAction func showChatWithBroadcastPreview(_ sender: AnyObject) {
        let spec = Constants.kSquareImageSpec
        let image = TDSImage(thumbnail: spec, src: spec, origin: spec)
        let block = TDSMessageInnerBlock(link: "https://tw.yahoo.com", image: image, id: "mockId")
        let message = TDSMessageCollection(title: "韓國經典條紋加厚柔軟長袖黑上衣", blocks: [block], theme: nil, event: nil)
        self.showChatWithPreviewMessage(message: message)
    }

    @IBAction func showChatWithExpiredLotteryEvent(_ sender: AnyObject) {
        let expiredEventId = "4e5d93f1-c2cd-4b65-ae0f-09f4048056d3"
        let message = self.makeMockEventLotteryMessage(with: expiredEventId)
        message.meta.messageId = "mock-lottery-message-id"
        guard DemoAccountManager.shared.yid == "yqa_tw_api_qe34" || DemoAccountManager.shared.yid == "yqa_tw_api_qe35" else { return }
        let channelId = "baf87ccb-7113-4ff9-94ca-2597e39fd2b1"
        let vc = TDSFactory.makeMessagingViewController(with: channelId)
        vc.delegate = self
        vc.dataSource = self
        let navi = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
        vc.postMessage(message, replyToHint: false, completion: nil)
    }

    @IBAction func showBroadcastChannel(_ sender: AnyObject) {
        guard let channelId = self.broadcastChannelId,
              !channelId.isEmpty else { return }
        let vc = TDSFactory.makeMessagingViewController(with: channelId)
        vc.delegate = self
        vc.dataSource = self
        let navi = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func showActivityChatAsB2bUser(_ sender: AnyObject) {
        // beta env
        let channelId = "c42c3865-4661-4282-b791-9590033c39b3"
        // b2b id: csstest@yahoo.com.tw, name: "Yahoo aas test0706-2"
        let imUserId = "5EB0EC30-DE73-4325-8416-49D685D93722"
        TDSFactory.makeMessagingViewController(with: channelId, imUserId: imUserId, loginType: .b2b) { error, vc in
            guard let vc = vc else {
                let description = (error as? TDSError)?.errorDescription ?? error?.localizedDescription
                self.tds_showAlert(title: "Failed", message: description)
                return
            }
            vc.dataSource = self
            vc.delegate = self
            let navi = TDSNavigationController(rootViewController: vc)
            // swiftlint:disable use_tds_present
            self.present(navi, animated: true, completion: nil)
            // swiftlint:enable:previous
        }
    }

    @IBAction func showActivityChatAsYahooUser(_ sender: AnyObject) {
        guard let imUserId = TDSServiceManager.shared.currentUserId else {
            self.tds_showAlert(title: "Failed", message: "User is not login yet")
            return
        }
        TDSFactory.makeMessagingViewController(with: self.activityChannelId, imUserId: imUserId, loginType: .cookies) { error, vc in
            guard let vc = vc else {
                let description = (error as? TDSError)?.errorDescription ?? error?.localizedDescription
                self.tds_showAlert(title: "Failed", message: description)
                return
            }
            vc.dataSource = self
            vc.delegate = self
            let navi = TDSNavigationController(rootViewController: vc)
            // swiftlint:disable use_tds_present
            self.present(navi, animated: true, completion: nil)
            // swiftlint:enable:previous
        }
    }

    @IBAction func showActivityChatWithAliasId(_ sender: AnyObject) {
        let aliasId = "muse"
        TDSFactory.makeMessagingViewController(with: aliasId) { (error, vc) in
            guard error == nil else {
                if let err = error as? TDSError {
                    self.tds_showAlert(title: "Failed", message: err.localizedMessage)
                } else {
                    self.tds_showAlert(title: "Failed", message: "makeMessagingViewController with aliasId failed!")
                }
                return
            }
            guard let vc = vc else {
                self.tds_showAlert(title: "Failed", message: "聊天室不存在")
                return
            }
            vc.dataSource = self
            vc.delegate = self
            let navi = TDSNavigationController(rootViewController: vc)
            // swiftlint:disable use_tds_present
            self.present(navi, animated: true, completion: nil)
            // swiftlint:enable:previous
        }
    }

    @IBAction func showActivityChatWithUrlString(_ sender: AnyObject?) {
        let testUrlString = "https://tw.bc.yahoo.com/p/muse"
        let alertController = UIAlertController(title: "請輸入待測試 urlString", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = testUrlString
        }
        alertController.addAction(UIAlertAction(title: "測試", style: .default, handler: { [weak self] (action) in
            guard let urlString = alertController.textFields?.first?.text else { return }
            guard !urlString.isEmpty else {
                self?.tds_topViewController.tds_showAlert(title: "Invalid urlString")
                return
            }

            if TDSFactory.canHandle(urlString) {
                TDSFactory.makeViewController(urlString: urlString) { error, vc in
                    guard error == nil,
                          let vc = vc else {
                        self?.tds_topViewController.tds_showAlert(title: "\(urlString) 建立聊天室失敗", message: (error as? TDSError)?.localizedMessage)
                        return
                    }
                    if let vc = vc as? TDSMessagingViewController {
                        vc.dataSource = self
                        vc.delegate = self
                    }

                    let navi = TDSNavigationController(rootViewController: vc)
                    // swiftlint:disable use_tds_present
                    self?.present(navi, animated: true, completion: nil)
                    // swiftlint:enable:previous
                }

            // canHandle, as a result, present VC in callback
            } else {
                self?.tds_topViewController.tds_showAlert(title: "無法識別 \(urlString)")
            }
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.tds_topViewController.present(alertController, animated: true, completion: nil)
    }

    @IBAction func showVideoView(_ sender: AnyObject) {
        let vc = DemoVideoViewController()
        let navi = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func showVideoViewController(_ sender: AnyObject) {
        let vc = YMGVideoViewController(with: URL(string: "https://edgecast-vod.yahoo.net/aws-oath-nevec-aws-prod/destination/edbabd3714d8479993f486cbbf9d1e0e/edbabd3714d8479993f486cbbf9d1e0e_720p.mp4")!)
        vc.handler = YMGAVPlayerHandler.shared
        let navi = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func b2bLogin(_ sender: AnyObject?) {
        DemoAccountManager.shared.refreshB2BToken(on: self) { [weak self] (error, passportToken)  in
            DispatchQueue.main.async {
                if let passportToken = passportToken {
                    TDSAccountManager.shared.passportToken = passportToken
                }
                guard let strongSelf = self else { return }
                let title = passportToken != nil ? "B2B Login Success" : "B2B Login Failed"
                strongSelf.tds_topViewController.tds_showAlert(title: title, message: String(describing: error?.localizedDescription))
            }
        }
    }

    @IBAction func b2bLogout(_ sender: AnyObject) {
        TDSAccountManager.shared.resetAccounts(for: .b2b)
        DemoAccountManager.shared.logoutB2B()
    }
}

// MARK: Shopping case
extension DemoViewController {
    @IBAction func showDoveTestByAliasId(_ sender: AnyObject) {
        let aliasId = "dovetest"
        TDSFactory.makeMessagingViewController(with: aliasId) { (error, vc) in
            guard error == nil else {
                if let err = error as? TDSError {
                    self.tds_showAlert(title: "Failed", message: err.localizedMessage)
                } else {
                    self.tds_showAlert(title: "Failed", message: "makeMessagingViewController with aliasId failed!")
                }
                return
            }
            guard let vc = vc else {
                self.tds_showAlert(title: "Failed", message: "聊天室不存在")
                return
            }
            vc.dataSource = self
            vc.delegate = self
            let navi = TDSNavigationController(rootViewController: vc)
            // swiftlint:disable use_tds_present
            self.present(navi, animated: true, completion: nil)
            // swiftlint:enable:previous
        }
    }

    @IBAction func showDoveTestByChannelId(_ sender: AnyObject) {
        let channelId = (self.environmentSegControl.selectedSegmentIndex == 0) ? "b8c33b49-5cea-4b99-bff8-40b1003d1f93" : "f0e0bcbe-ffb2-4c1a-9ae7-9d716a59a42c"
        let vc = TDSFactory.makeMessagingViewController(with: channelId)
        vc.dataSource = self
        vc.delegate = self
        let navi = TDSNavigationController(rootViewController: vc)
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func showWacoalTestByAliasId(_ sender: AnyObject) {
        let aliasId = "wacoal"
        TDSFactory.makeMessagingViewController(with: aliasId) { (error, vc) in
            guard error == nil else {
                if let err = error as? TDSError {
                    self.tds_showAlert(title: "Failed", message: err.localizedMessage)
                } else {
                    self.tds_showAlert(title: "Failed", message: "makeMessagingViewController with aliasId failed!")
                }
                return
            }
            guard let vc = vc else {
                self.tds_showAlert(title: "Failed", message: "聊天室不存在")
                return
            }
            vc.dataSource = self
            vc.delegate = self
            let navi = TDSNavigationController(rootViewController: vc)
            // swiftlint:disable use_tds_present
            self.present(navi, animated: true, completion: nil)
            // swiftlint:enable:previous
        }
    }

    @IBAction func selectImageToUpload(_ sender: AnyObject) {
        self.validatePhotoLibraryPermissiion(self, kUTTypeImage as String)
    }

    @IBAction func selectVideoToUpload(_ sender: AnyObject) {
        self.validatePhotoLibraryPermissiion(self, kUTTypeMovie as String)
    }

    private func uploadMediaToPixelFrame(picker: UIImagePickerController, info: [UIImagePickerController.InfoKey: Any]) {
        // https://git.ouryahoo.com/EC-Mobile/tripledots_android/pull/3865/files#diff-3f6cc33b1610a33f43c8eb5bbfa99068c89013edb24ba6ae5c49080eac9a1bdcR47-R59
        if picker.mediaTypes == [kUTTypeImage as String] {
            guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
                  let object = try? TDSPixelFrameUploadObject(content: image,
                                                              targetType: "review",
                                                              targetId: "image",
                                                              appName: "shopping_product_rating",
                                                              resizingProfile: "shopping_product_rating") else {
                assert(false, "Unable to make UploadObject")
                return
            }

            let identifier = UUID().uuidString
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "圖片上傳進度", message: "0 %", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "取消", style: .default, handler: { _ in
                    TDSServiceManager.shared.cancelUploadTask(for: identifier)
                }))
                // swiftlint:disable use_tds_present
                self.present(alertController, animated: true, completion: nil)
                // swiftlint:enable:previous
                TDSServiceManager.shared.upload(object: object, identifier: identifier) { progress in
                    DispatchQueue.main.async {
                        alertController.message = String(format: "%.2f %%", progress * 100)
                    }
                } completion: { response, error in
                    DispatchQueue.main.async {
                        if let image = response as? TDSImage {
                            alertController.title = "圖片上傳成功"
                            alertController.message = (image.src?.url ?? image.thumbnail.url)?.absoluteString
                        } else {
                            alertController.title = "圖片上傳失敗"
                            alertController.message = error?.localizedDescription
                        }
                    }
                }
            }
        } else if picker.mediaTypes == [kUTTypeMovie as String] {
            guard let phAsset = info[.phAsset] as? PHAsset else {
                assert(false, "Unable to make UploadObject")
                return
            }

            // NOTE: we don't support iCloud, so we need to set network access to false.
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false

            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { (asset, audioMix, assetInfo) in
                guard let urlAsset = asset as? AVURLAsset, // NOTE: asset will always sucess in transform, but asset itself is optional
                      (assetInfo?[PHImageResultIsInCloudKey] as? Int) != 1,
                      assetInfo?[PHImageErrorKey] == nil,
                      let object = try? TDSPixelFrameUploadObject(content: urlAsset,
                                                                  targetType: "review",
                                                                  targetId: "video",
                                                                  appName: "shopping_product_rating",
                                                                  transcodingProfile: "shopping_product_rating") else {
                    // TODO: asset in on iCloud
                    assert(false, "Unable to make UploadObject")
                    return
                }
                let identifier = UUID().uuidString
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "影片上傳進度", message: "0 %", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "取消", style: .default, handler: { _ in
                        TDSServiceManager.shared.cancelUploadTask(for: identifier)
                    }))
                    // swiftlint:disable use_tds_present
                    self.present(alertController, animated: true, completion: nil)
                    // swiftlint:enable:previous
                    TDSServiceManager.shared.upload(object: object, identifier: identifier) { progress in
                        DispatchQueue.main.async {
                            alertController.message = String(format: "%.2f %%", progress * 100)
                        }
                    } completion: { response, error in
                        DispatchQueue.main.async {
                            if let video = response as? TDSVideo {
                                alertController.title = "影片上傳成功"
                                alertController.message = (video.src?.url ?? video.thumbnail.url)?.absoluteString
                            } else {
                                alertController.title = "影片上傳失敗"
                                alertController.message = error?.localizedDescription
                            }
                        }
                    }
                }
            }
        } else {
            assert(false, "Unhandled mediaType")
        }
    }
}

// MARK: Custom case
extension DemoViewController {
    /*@IBAction func showJomaChannelList(_ sender: AnyObject) {
        self.setupService()
        // swiftlint:disable use_svcmgr_channelInfoInit
        let vc = JMChannelListViewController()
        let navi = TDSNavigationController(rootViewController: vc)
        vc.navigationItem.rightBarButtonItem = navi.defaultCloseBarButtonItem()
        let themeType: TDSThemeType = self.themeSegControl.selectedSegmentIndex == 0 ? .auction : .auctionDark
        vc.view.backgroundColor = TDSTheme(type: themeType).backgroundLevel4
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true, completion: nil)
        // swiftlint:enable:previous
    }

    @IBAction func showJomaGroupChat(_ sender: AnyObject) {
        self.setupService()
        self.presentJMMessagingVc(with: JMChannelInfoAggregator(channelId: Constants.jomaMockGroupChannelId))
    }

    @IBAction func joinJomaGroupChat(_ sender: AnyObject) {
        self.setupService()
        var textField: UITextField?
        let goAction = UIAlertAction(title: "Go!", style: .default) { [weak self] (action) in
            guard let strongSelf = self,
                  let channelId = textField?.text else { return }
            TDSServiceManager.shared.getChannel(with: channelId) { (channel, error) in
                guard error == nil,
                      let channel = channel else {
                    TDSServiceManager.shared.tdsr_joinChannel(with: channelId) { (channel, error) in
                        guard error == nil,
                              let channel = channel else { return }
                        strongSelf.presentJMMessagingVc(with: JMChannelInfoAggregator(channel: channel), toast: "Join Channel 成功", toastStyle: .success)
                    }
                    return
                }
                strongSelf.presentJMMessagingVc(with: JMChannelInfoAggregator(channel: channel), toast: "已經join過了，直接開啟Channel", toastStyle: .success)
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        textField = self.showTextFieldAlert(title: "Joma Channel", message: "請輸入 channelId", text: Constants.jomaMockGroupChannelId, actions: [goAction, cancelAction])
    }

    @IBAction func leaveJomaGroupChat(_ sender: AnyObject) {
        self.setupService()
        var textField: UITextField?
        let goAction = UIAlertAction(title: "Go!", style: .default) { [weak self] (action) in
            guard let strongSelf = self,
                  let channelId = textField?.text else { return }
            TDSServiceManager.shared.tdsr_leaveChannel(with: channelId) { (error) in
                guard error == nil else {
                    strongSelf.ymgPresentToast(message: "Leave Channel 失敗，可能已經不在Channel中了", style: .warning)
                    return
                }
                strongSelf.ymgPresentToast(message: "Leave Channel 成功", style: .success)
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        textField = self.showTextFieldAlert(title: "Joma Channel", message: "請輸入 channelId", text: Constants.jomaMockGroupChannelId, actions: [goAction, cancelAction])
    }

    private func presentJMMessagingVc(with channelInfo: JMChannelInfoAggregator, toast: String? = nil, toastStyle: YMGToastStyle = .success) {
        // swiftlint:disable use_svcmgr_channelInfoInit
        let vc = JMMessagingViewController(channelInfo: channelInfo)
        // swiftlint:enable:previous
        vc.delegate = self
        vc.dataSource = self
        let navi = TDSNavigationController(rootViewController: vc)
        vc.navigationItem.rightBarButtonItem = navi.defaultCloseBarButtonItem()
        let themeType: TDSThemeType = self.themeSegControl.selectedSegmentIndex == 0 ? .auction : .auctionDark
        vc.view.backgroundColor = TDSTheme(type: themeType).backgroundLevel4
        // swiftlint:disable use_tds_present
        self.present(navi, animated: true) { [weak navi] in
            guard let toast = toast else { return }
            navi?.ymgPresentToast(message: toast, style: toastStyle)
        }
        // swiftlint:enable:previous
    }*/

    @discardableResult
    private func showTextFieldAlert(title: String? = nil, message: String? = nil, text: String? = nil, actions: [UIAlertAction]? = nil) -> UITextField? {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.clearButtonMode = .always
            textField.text = text
        }
        actions?.forEach { (action) in
            alertController.addAction(action)
        }
        self.tds_topViewController.present(alertController, animated: true, completion: nil)
        return alertController.textFields?.first
    }
/*
    private func getJomaEnviromentParameters(_ completion: @escaping (_ token: String?, _ userId: String?, _ brandId: String?, _ domain: String?) -> Void) {
        let url = URL(string: "https://auth-yahoo-sat.baby.juiker.net/oauth2/getUserTokenByTurnkey")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("yjoma", forHTTPHeaderField: "Brand-Id")
        let str = "yjoma_backend:ci0MbDksTUZnKcoNiRIc".data(using: .utf8)?.base64EncodedString()
        request.addValue("Basic \(str!)", forHTTPHeaderField: "Authorization")
        let body = try? JSONEncoder().encode(["UID": "joma-ios-test-00001"])
        request.httpBody = body
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data,
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                completion(nil, nil, nil, nil)
                return
            }
            DemoLogger.shared.info("\(jsonObject)")

            completion(jsonObject["accessToken"] as? String, jsonObject["userID"] as? String, "yjoma", "im-sat-yjoma.baby.juiker.net")
        }

        task.resume()
    }
*/
}

// MARK: API cases
extension DemoViewController {
    @IBAction func showAPICases(_ sender: AnyObject) {
        // TODO: Add alertController/tableViewController later if more cases added
        self.queryEntityByAliasId(sender)
    }

    @IBAction func queryEntityByAliasId(_ sender: AnyObject) {
        let criteria = TDSEntityCriteria(alias: "top1")
        TDSServiceManager.shared.queryEntities(with: criteria) { [weak self] (entities, _, _) in
            DispatchQueue.main.async {
                guard let strongSelf = self,
                      let entity = entities?.first else { return }
                let message = "title: \(String(describing: entity.decodedTitle))\nimChannelId: \(String(describing: entity.imChannelId))\nalias: \(String(describing: entity.alias))"
                strongSelf.tds_showAlert(title: #function, message: message)
            }
        }
    }
}

// MARK: Notification handlers
extension DemoViewController {
    func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleSignInStatus(notification:)), name: .pwAccountsEventSignInSuccess, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleSignInStatus(notification:)), name: .pwAccountsEventDidSignOut, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateConnectionStatus(notification:)), name: .tdsServiceDidConnect, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateConnectionStatus(notification:)), name: .tdsServiceDidDisconnect, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateConnectionStatus(notification:)), name: .tdsServiceOnConnecting, object: nil)
    }

    @IBAction func updateConnectionStatus(notification: Notification) {
        if notification.name == Notification(name: .tdsServiceDidConnect).name {
            self.connectionStatusLabel.text = "Connected"
        } else if notification.name == Notification(name: .tdsServiceDidDisconnect).name {
            self.connectionStatusLabel.text = "Disconnected"
        } else if notification.name == Notification(name: .tdsServiceOnConnecting).name {
            self.connectionStatusLabel.text = "Connecting"
        }
    }

    @IBAction func handleSignInStatus(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.service.disconnect()
            strongSelf.connectionStatusLabel.text = "Disconnected"

            if notification.name == .pwAccountsEventSignInSuccess {
                strongSelf.accountLabel.text = DemoAccountManager.shared.yid
                #if YBUILD_AUTOMATIONTEST
                #else
                strongSelf.connect(UIButton())
                #endif
            } else if notification.name == .pwAccountsEventDidSignOut {
                strongSelf.accountLabel.text = ""
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension DemoViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let index = self.propertyToIndex(self.currentProperty) else { return 0}
        return self.showCases?[index - 1].count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.kTableViewCellDefaultIdentifier, for: indexPath)
        guard let index = self.propertyToIndex(self.currentProperty),
              let cases = self.showCases?[index - 1] else { return cell }
        if cases.count > indexPath.row {
            cell.textLabel?.text = cases[indexPath.row][0]
            cell.accessibilityIdentifier = cell.textLabel?.text
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let index = self.propertyToIndex(self.currentProperty),
              let cases = self.showCases?[index - 1] else { return }
        if cases.count > indexPath.row {
            let selector = NSSelectorFromString(cases[indexPath.row][1])
            if self.responds(to: selector) {
                self.perform(selector, with: nil)
            }
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Displayed as separator
        return 1
    }
}

// MARK: UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension DemoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var viewController = picker.presentingViewController
        if let tabController = viewController as? DemoTabBarController {
            viewController = tabController.selectedViewController
        }
        if let naviController = viewController as? UINavigationController {
            viewController = naviController.viewControllers.last
        }
        if let messagingViewController = viewController as? TDSMessagingViewControllerProtocol {
            messagingViewController.postContent(info, replyToHint: true)

        } else if let drawerVC = viewController as? YMGDrawerContainerViewController,
                  let messagingVC = drawerVC.children.first(where: { $0 is TDSMessagingViewControllerProtocol}) as? TDSMessagingViewControllerProtocol {
            messagingVC.postContent(info, replyToHint: true)

        } else if let editorVC = viewController as? TDSGenericEditorViewControllerProtocol {
            editorVC.sendContent(info)

        } else if viewController == self {
            // ABUMOBILE-12451 Custom config for uploading media content to pixelFrame
            self.uploadMediaToPixelFrame(picker: picker, info: info)

        } else {
            assert(false, "can't find messaging view controller")
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: DemoBroadcastEditorViewControllerDelegate
extension DemoViewController: DemoBroadcastEditorViewControllerDelegate {
    func demoBroadcastEditorViewController(_ viewController: DemoBroadcastEditorViewController, didWantToSend message: TDSMessageProtocol) {
        guard let channelActionInteractiveVC = self.channelActionInteractiveVC else { return }
        channelActionInteractiveVC.postMessage(message, replyToHint: true) { (error) in
            guard error == nil else { return }
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: TDSGenericEditorViewControllerDelegate
extension DemoViewController: TDSGenericEditorViewControllerDelegate {
    public func editorViewController(_ viewController: UIViewController & TDSGenericEditorViewControllerProtocol, shouldHandleAction action: TDSGenericEditorAction) -> Bool {
        switch action {
        case .camera:
            // 開啟相機
            self.validateCameraPermissiion(viewController, kUTTypeImage as String)
            return false

        case .photo, .video:
            self.validatePhotoLibraryPermissiion(viewController, (action == .video ? kUTTypeMovie : kUTTypeImage) as String)
            return false

        case .custom:
            return false
        }
    }
}

// MARK: TDSChatRoomEditorViewControllerDelegate
extension DemoViewController: TDSChatRoomEditorViewControllerDelegate {
    public func chatRoomEditorViewController(_ viewController: VerizonMediaTripleDots.TDSChatRoomEditorViewController, didCreate channelId: String?, error: Error?) {
        self.channelIdFromEditor = channelId
        if channelId == nil {
            DispatchQueue.main.async {
                let errorMessage = (error as? TDSError)?.errorDescription ?? error?.localizedDescription
                self.tds_showAlert(title: "Failed to create chat room", message: errorMessage)
            }
        }
    }
}
