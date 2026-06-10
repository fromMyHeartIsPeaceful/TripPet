import Foundation

enum AppCopy {
    enum Tabs {
        static let cabin = "小屋"
        static let mailbox = "邮箱"
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
        static let laterButton = "稍后再说"
        static let enterCabinButton = "进入小屋"
        static let connectingButton = "正在连接"
        static let settingsUnavailable = "当前设备不可读取 Health 步数"
        static let settingsNotDetermined = "还没有请求 Health 步数权限"
        static let settingsDenied = "Health 步数权限未开启"
        static let settingsAuthorized = "Health 已连接，可以读取今日步数"
        static let settingsReadPermissionRequested = "已请求 Health 步数读取权限，会在赠送时尝试读取今日步数"
        static let settingsRequestFailed = "暂时没有连上 Health。可以稍后再试，或在系统设置里检查权限。"

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
        static let healthRequestFailed = "暂时没有连上 Health。可以稍后再试，或在设置里检查权限。"
        static let keepLooking = "没关系，小屋会一直亮着灯。等想出发时，再把今天的脚步送给小动物。"
        static let stepReadFailed = "暂时没有读到今天的脚步。可以稍后再试，或在设置里检查 Health 权限。"
        static let gifted = "机票已经送出。小动物收好地图，准备出发了。"
        static let ruleHint = "达到3000步可赠送1张机票"
        static let connectButton = "连接 Apple 健康"
        static let giftButton = "赠送今日脚步，让它出发"
        static let readingStepsButton = "正在读取今日脚步"
        static let connectingHealthButton = "正在连接健康"
        static let keepLookingButton = "先看看小屋"
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
        static let alreadyGifted = "今天的脚步已经送出去了。等这趟旅行寄回明信片，再准备下一张机票吧。"
        static let eligible = "今天可以赠送 1 张机票"

        static func notEnoughSteps(todaySteps: Int, requiredSteps: Int) -> String {
            "Apple 健康今天读取到 \(todaySteps) 步。走到 \(requiredSteps) 步后，就可以把脚步折成 1 张机票。"
        }
    }

    enum GiftConfirmation {
        static let title = "确认赠送"
        static let subtitle = "把今天的脚步折成一张机票"
        static let cancelButton = "再想想"
        static let confirmButton = "确认赠送"
        static let workingButton = "正在赠送"

        static func ticketLine(count: Int) -> String {
            "步数已达成赠送机票条件"
        }

        static func stepsLine(steps: Int) -> String {
            "\(steps) 步来自 Apple 健康"
        }

        static func wishLine(animalName: String, destination: String) -> String {
            "\(animalName)想去\(destination)"
        }
    }

    enum Mailbox {
        static let title = "邮箱"
        static let emptyTitle = "邮箱还很安静"
        static let emptyBody = "等待小动物从路上寄来明信片..."
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
        static let versionTitle = "MVP 版本"
        static let versionBody = "当前包含小屋、邮箱、明信片、Health 步数读取和基础旅行规则。"

        static func collectionCount(_ count: Int) -> String {
            "已经收好 \(count) 张读过的明信片。"
        }
    }
}
