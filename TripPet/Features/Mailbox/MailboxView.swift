import SwiftUI

struct MailboxView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = MailboxViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                VStack(alignment: .leading, spacing: 14) {
                    header

                    ArtImage(name: "mailbox_tray_base")
                        .frame(maxWidth: .infinity)
                        .frame(height: 128)
                        .padding(.top, -6)

                    Text("今天可能会有远方来信")
                        .font(AppTheme.body)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, -4)

                    if environment.repository.postcards.isEmpty {
                        MailboxEmptyState()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                ForEach(environment.repository.postcards) { postcard in
                                    EnvelopeRow(postcard: postcard, reduceMotion: reduceMotion) {
                                        viewModel.open(postcard, repository: environment.repository)
                                    }
                                }
                            }
                            .padding(.bottom, 112)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .navigationBarHidden(true)
            .task {
                environment.revealEligiblePostcards()
            }
            .fullScreenCover(item: $viewModel.selectedPostcard) { postcard in
                PostcardDetailView(postcard: postcard)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppCopy.Mailbox.title)
                .font(AppTheme.pageTitle)
                .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct EnvelopeRow: View {
    private static let envelopeHeight: CGFloat = 150

    let postcard: Postcard
    let reduceMotion: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ArtImage(name: envelopeAssetName)
                .frame(maxWidth: .infinity)
                .frame(height: Self.envelopeHeight)
                .opacity(postcard.isRead ? 0.86 : 1)
                .overlay {
                    GeometryReader { proxy in
                        envelopeTitle
                            .frame(width: proxy.size.width * 0.58, alignment: .center)
                            .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.24)
                    }
                }
            .foregroundStyle(AppTheme.ink)
            .scaleEffect(isHovering && reduceMotion == false ? 1.018 : 1)
            .offset(y: isHovering && reduceMotion == false ? -2 : 0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 20, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = pressing
            }
        }, perform: {})
        .accessibilityLabel("打开来自\(postcard.destination)的明信片：\(postcard.title)")
    }

    private var envelopeTitle: some View {
        Text("\(postcard.senderName)寄来的明信片")
            .font(.system(size: 21, weight: .semibold))
            .foregroundStyle(AppTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)
    }

    private var envelopeAssetName: String {
        postcard.isRead ? "envelope_read" : "envelope_unread"
    }
}

private extension Postcard {
    var senderName: String {
        if let range = title.range(of: "寄来的明信片") {
            let name = title[..<range.lowerBound]
            if name.isEmpty == false {
                return String(name)
            }
        }

        if animalAssetName.contains("dog") {
            return "小狗"
        } else if animalAssetName.contains("rabbit") {
            return "小兔"
        } else if animalAssetName.contains("cat") {
            return "小猫"
        }

        return "小动物"
    }
}

private struct MailboxEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            ArtImage(name: "envelope_old")
                .frame(width: 150, height: 92)
                .opacity(0.72)

            VStack(spacing: 6) {
                Text(AppCopy.Mailbox.emptyTitle)
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.ink)
                Text(AppCopy.Mailbox.emptyBody)
                    .font(AppTheme.body)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .paperCard(cornerRadius: 24)
    }
}

#Preview("Mailbox with letters") {
    MailboxView()
        .environmentObject(AppEnvironment.preview())
}

#Preview("Mailbox empty") {
    MailboxView()
        .environmentObject(
            AppEnvironment.preview(
                seed: SeedData(
                    animals: SeedData.preview.animals,
                    travelWishes: SeedData.preview.travelWishes,
                    trips: [],
                    postcards: []
                )
            )
        )
}
