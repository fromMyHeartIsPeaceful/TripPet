import SwiftUI
import UIKit

struct ArtImage: View {
    enum ContentMode {
        case fit
        case fill

        var swiftUIContentMode: SwiftUI.ContentMode {
            switch self {
            case .fit:
                return .fit
            case .fill:
                return .fill
            }
        }
    }

    var name: String
    var contentMode: ContentMode = .fit
    var isDecorative: Bool = true
    var cornerRadius: CGFloat = 0
    var showsShadow: Bool = false

    var body: some View {
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .renderingMode(name.hasPrefix("icon_") ? .template : .original)
                    .aspectRatio(contentMode: contentMode.swiftUIContentMode)
            } else {
                fallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: AppTheme.oliveInk.opacity(showsShadow ? 0.12 : 0), radius: 8, x: 0, y: 4)
        .accessibilityHidden(isDecorative)
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.cornerRadius), style: .continuous)
                .fill(AppTheme.ivory)
            RoundedRectangle(cornerRadius: max(cornerRadius, AppTheme.cornerRadius), style: .continuous)
                .stroke(AppTheme.paperGray, style: StrokeStyle(lineWidth: AppTheme.hairline, dash: [6, 6]))

            #if DEBUG
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(6)
            #else
            Image(systemName: "photo")
                .foregroundStyle(AppTheme.paperGray)
            #endif
        }
    }
}

struct DashedPlaceholder: View {
    var title: String

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .stroke(
                AppTheme.ink,
                style: StrokeStyle(lineWidth: AppTheme.hairline, dash: [6, 6])
            )
            .overlay {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
    }
}

struct StepCounterView: View {
    static let defaultLimit = 3000

    let value: Int
    var limit: Int = defaultLimit

    static func displayText(value: Int, limit: Int = defaultLimit) -> String {
        let clampedLimit = max(0, limit)
        let clampedValue = min(max(value, 0), clampedLimit)
        return String(format: "%04d", clampedValue)
    }

    private var clampedLimit: Int {
        max(0, limit)
    }

    private var digits: [Int] {
        Self.displayText(value: value, limit: clampedLimit).compactMap { Int(String($0)) }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(Self.displayText(value: value, limit: clampedLimit))
                .foregroundStyle(AppTheme.ink)

            Text("/" + String(clampedLimit))
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.9)
        .fixedSize(horizontal: true, vertical: false)
        .contentTransition(.numericText())
        .animation(.easeOut(duration: 0.28), value: digits)
        .accessibilityLabel("今天的步数 \(Self.displayText(value: value, limit: clampedLimit)) / \(clampedLimit)")
    }
}

struct RollingDigitView: View {
    let digit: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.paperWhite.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.paperGray.opacity(0.78), lineWidth: AppTheme.hairline)
                )

            Text("\(digit)")
                .id(digit)
                .font(.system(size: 30, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.ink)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
        }
        .frame(width: 28, height: 40)
        .clipped()
    }
}
