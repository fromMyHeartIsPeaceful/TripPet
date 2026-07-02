import Foundation

enum AppCopy {
    enum Tabs {
        static let cabin = "小屋"
        static let achievements = "成就"
        static let mailbox = "邮箱"
        static let map = "地球"
    }

    enum Onboarding {
        static let title = "步履小屋"
        static let body = "把今天走过的路，变成一张机票，送小动物们去世界各地旅行。"
        static let startButton = "进入小屋"
    }

    enum Health {
        static let connectTitle = "连接 Apple 健康"
        static let connectIntro = "授权步履小屋获取Apple健康的步数，用于将你的每日脚步转化为送小动物全球旅行的机票"
        static let localOnly = "Apple健康的步数数据，只在本地使用。不会发送到外部。"
        static let unavailable = "这台设备暂时不能读取 Health 步数。你仍然可以先进入小屋，等之后可以连接时再回来设置。"
        static let denied = "Health 步数权限还没有开启。你可以稍后在设置里重新连接，小屋会一直等着。"
        static let authorized = "已经连接好了。今天的脚步可以成为小动物去远方的机票。"
        static let readPermissionRequested = "已经请求过步数读取权限。接下来会直接尝试读取今日步数，如果系统里关闭了权限，可以到 iPhone 设置或健康 App 中重新打开。"
        static let requestFailed = "暂时没有连上。可以先进入小屋，之后在设置里再试一次。"
        static let requestUnchanged = "还没有取得 Health 步数权限。可以先进入小屋，之后在设置里再试一次。"
        static let stepReadWillContinue = "Apple 健康已连接。今天的步数会在小屋里继续读取，如果暂时没显示，可以稍后再试。"
        static let laterButton = "稍后再说"
        static let enterCabinButton = "进入小屋"
        static let retryReadButton = "重试读取今日步数"
        static let connectingButton = "正在连接"
        static let settingsUnavailable = "当前设备不可读取 Health 步数"
        static let settingsNotDetermined = "还没有请求 Health 步数权限"
        static let settingsDenied = "Health 步数权限未开启"
        static let settingsAuthorized = "Health 已连接，可以读取今日步数"
        static let settingsReadPermissionRequested = "已请求 Health 步数读取权限，会在赠送时尝试读取今日步数"
        static let settingsRequestFailed = "暂时没有连上 Health。可以稍后再试，或在系统设置里检查权限。"
        static let stepSyncPending = "等待Apple健康同步数据"

        static func todayStepsRead(_ steps: Int) -> String {
            "Apple 健康今天读取到 \(steps) 步。"
        }
    }

    enum Cabin {
        static let title = "小屋"
        static let todayStepsTitle = "今天的步数"
        static let defaultAction = "把今天走过的路，变成一张机票，送小动物们去世界各地旅行。"
        static let healthUnavailable = "这台设备暂时不能读取 Health 步数。小屋仍然在这里，等可以连接时再把脚步送给小动物。"
        static let healthNotDetermined = "连接健康后，小动物才能收到今日脚步。这里只读取每日步数，用来折成旅行机票。"
        static let healthDenied = "Health 步数权限还没有开启。连接后，小动物才能收到今日脚步。"
        static let healthReadPermissionRequested = "已请求 Health 步数读取权限。小屋会在赠送时读取今日步数，把脚步折成机票。"
        static let healthReconnectPrompt = "连接 Apple 健康后，才能读取今日步数，把脚步折成小动物的机票。"
        static let healthRequestFailed = "暂时没有连上 Health。可以稍后再试，或在设置里检查权限。"
        static let stepReadFailed = "Apple 健康已连接，但暂时没有读到今天的脚步。可以稍后重试读取。"
        static let healthSyncPending = "等待Apple健康同步数据"
        static let gifted = "机票已经送出。小动物收好地图，准备出发了。"
        static let ruleHint = "达到3000步可赠送1张机票"
        static let firstTicketRuleHint = "首张机票已准备好"
        static let firstTicketGiftedSummary = "已使用首张机票"
        static let connectButton = "连接 Apple 健康"
        static let reconnectButton = "重新连接 Apple 健康"
        static let retryStepReadButton = "重试读取今日步数"
        static let giftButton = "赠送今日脚步，让它出发"
        static let firstTicketGiftButton = "赠送第一张机票，让它出发"
        static let readingStepsButton = "正在读取今日脚步"
        static let connectingHealthButton = "正在连接健康"
        static let tripReturnHint = "预计明天寄来明信片"
        static let tripStatus = "旅途中"
        static let emptyCabinTitle = "也许会有更多小动物来到小屋..."
        static let emptyCabinBody = ""
        static let dailyLimitReached = "今天已经送出 3 张机票。小屋会在明天继续迎接小动物们。"

        static func activeTripMessage(animalName: String, destination: String) -> String {
            "\(animalName)已经在去\(destination)的路上。等明信片寄回来，再送出下一张机票吧。"
        }

        static func healthConnectedWithSteps(_ steps: Int, requiredSteps: Int) -> String {
            "Apple 健康今天读取到 \(steps) 步。走到 \(requiredSteps) 步后，就可以把脚步折成 1 张机票。"
        }

        static func giftedStepsSummary(totalSteps: Int, giftedSteps: Int) -> String {
            "今日总步数 \(totalSteps)，已赠送 \(giftedSteps) 步"
        }

        static func tripTitle(animalName: String, destination: String) -> String {
            "\(animalName)正在去\(destination)"
        }
    }

    enum TicketRule {
        static let alreadyGifted = "今天已经送出 3 张机票。小屋会在明天继续迎接小动物们。"
        static let eligible = "今天可以赠送 1 张机票"

        static func notEnoughSteps(todaySteps: Int, requiredSteps: Int) -> String {
            "Apple 健康今天读取到 \(todaySteps) 步。走到 \(requiredSteps) 步后，就可以把脚步折成 1 张机票。"
        }
    }

    enum GiftConfirmation {
        static let title = "确认赠送"
        static let subtitle = "把今天的脚步折成一张机票"
        static let chooseAnimalTitle = "选择一只小动物"
        static let cancelButton = "再想想"
        static let confirmButton = "确认赠送"
        static let workingButton = "正在赠送"
        static let firstTicketLine = "首张机票已经准备好"

        static func ticketLine(count: Int) -> String {
            "步数已达成赠送机票条件"
        }

        static func stepsLine(steps: Int) -> String {
            "\(steps) 步来自 Apple 健康"
        }
    }

    enum Mailbox {
        static let title = "邮箱"
        static let emptyTitle = "邮箱还很安静"
        static let emptyBody = "等待小动物从路上寄来明信片..."
        static let hasPostcardsPrompt = "点击邮箱收取明信片"
        static let emptyPrompt = "邮箱空空"
        static let emptyTapPrompts = [
            "小动物们会寄明信片来的，稍安勿躁",
            "世界上大约有2万种蝴蝶，不影响我依然是独特的那一只",
            "祝福你每天都有个好心情！"
        ]
    }

    enum Share {
        static let appName = "步履小屋"
        static let promo = "App Store搜索“步履小屋”"
        static let postcardAccessibilityLabel = "分享明信片"
        static let medalAccessibilityLabel = "分享勋章"
    }

    enum Settings {
        static let title = "设置"
        static let doneButton = "完成"
        static let healthTitle = "Apple 健康"
        static let healthButton = "连接或更新权限"
        static let notificationTitle = "通知"
        static let notificationDetail = "旅行回来时提醒我"
        static let notificationBody = "旅行回来时，可以让小屋轻轻提醒你有新明信片到了。第一版先记录偏好，真正的系统通知会在后续接入。"
        static let notificationToggle = "明信片寄回时提醒我"
        static let collectionTitle = "明信片收藏"
        static let collectionDetail = "整理收到的远方来信"
        static let collectionEmpty = "读过的明信片会收进这里。现在收藏夹还空着，等第一封远方来信被打开，它就会留下来。"
        static let aboutTitle = "关于步履小屋"
        static let aboutDetail = "版本与说明"
        static let aboutBody = "步履小屋把每日脚步变成小动物的旅行机票。它更像一本会慢慢长出来的手帐，而不是一个催促你完成目标的工具。"
        static let versionTitle = "1.0.8 版本"
        static let versionBody = "当前包含小屋、邮箱、可消耗明信片文本库、300 城市旅行地点库、世界地图旅行标记、Health 步数读取和基础旅行规则。"

        static func collectionCount(_ count: Int) -> String {
            "已经收好 \(count) 张读过的明信片。"
        }
    }

    enum Legal {
        static let signTitle = "设置与说明"
        static let title = "设置与说明"
        static let intro = "这里会放置步履小屋的协议、备案与联系信息。首版先预留入口，正式内容上线前会替换占位文案。"
        static let privacyTitle = "隐私协议"
        static let termsTitle = "用户协议"
        static let icpTitle = "中国区备案号"
        static let contactEmailTitle = "联系邮箱"
        static let privacyPlaceholder = "待补充正式隐私协议链接或正文。"
        static let termsPlaceholder = "待补充正式用户协议链接或正文。"
        static let icpPlaceholder = "待补充备案号。"
        static let contactEmailPlaceholder = "待补充联系邮箱。"
        static let doneButton = "知道了"
        static let signAccessibilityLabel = "打开设置与说明"
    }
}
