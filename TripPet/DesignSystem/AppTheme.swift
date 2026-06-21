import SwiftUI

enum AppTheme {
    static let paperWhite = Color(red: 1.0, green: 0.976, blue: 0.937)
    static let ivory = Color(red: 0.969, green: 0.933, blue: 0.863)
    static let sage = Color(red: 0.561, green: 0.686, blue: 0.584)
    static let deepSage = Color(red: 0.373, green: 0.498, blue: 0.4)
    static let mistBlue = Color(red: 0.663, green: 0.788, blue: 0.847)
    static let peach = Color(red: 0.914, green: 0.725, blue: 0.643)
    static let ochre = Color(red: 0.847, green: 0.702, blue: 0.416)
    static let oliveInk = Color(red: 0.239, green: 0.263, blue: 0.22)
    static let pencilGray = Color(red: 0.455, green: 0.463, blue: 0.435)
    static let paperGray = Color(red: 0.871, green: 0.839, blue: 0.78)

    static let ink = oliveInk
    static let paper = paperWhite
    static let softPaper = ivory
    static let faintLine = paperGray
    static let secondaryInk = pencilGray

    static let hairline: CGFloat = 1
    static let cornerRadius: CGFloat = 16

    static let pageTitle = Font.system(size: 32, weight: .semibold)
    static let cardTitle = Font.system(size: 22, weight: .semibold)
    static let sheetDescription = Font.system(size: 18)
    static let body = Font.system(size: 16)
    static let caption = Font.system(size: 15)
    static let button = Font.system(size: 16, weight: .semibold)
    static let tab = Font.system(size: 12, weight: .medium)

    static func postcardTitle(size: CGFloat) -> Font {
        .custom("LXGW WenKai Screen", size: size).weight(.semibold)
    }

    static func postcardBody(size: CGFloat) -> Font {
        .custom("LXGW WenKai Screen", size: size)
    }
}

struct PaperBackground: View {
    var body: some View {
        AppTheme.paperWhite
            .overlay {
                ArtImage(name: "texture_paper_grain", contentMode: .fill)
                    .opacity(0.08)
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
    }
}

struct PaperCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    var stroke: Color = AppTheme.paperGray

    func body(content: Content) -> some View {
        content
            .background(AppTheme.ivory)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: AppTheme.hairline)
            )
            .shadow(color: AppTheme.oliveInk.opacity(0.09), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func paperCard(cornerRadius: CGFloat = AppTheme.cornerRadius, stroke: Color = AppTheme.paperGray) -> some View {
        modifier(PaperCardModifier(cornerRadius: cornerRadius, stroke: stroke))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.button)
            .foregroundStyle(isEnabled ? AppTheme.paperWhite : AppTheme.secondaryInk.opacity(0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.deepSage.opacity(0.35), lineWidth: AppTheme.hairline)
            )
            .shadow(color: AppTheme.deepSage.opacity(isEnabled ? (configuration.isPressed ? 0.06 : 0.22) : 0.04), radius: 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .offset(y: configuration.isPressed ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.72)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return AppTheme.paperGray.opacity(0.64) }
        return isPressed ? AppTheme.deepSage : Color(red: 0.44, green: 0.66, blue: 0.47)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(configuration.isPressed ? AppTheme.paperGray.opacity(0.45) : AppTheme.ivory)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.paperGray, lineWidth: AppTheme.hairline)
            )
    }
}
