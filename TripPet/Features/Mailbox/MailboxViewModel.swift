import Combine
import Foundation

@MainActor
final class MailboxViewModel: ObservableObject {
    enum PostcardDetailSource: Equatable {
        case unreadStack
        case history
    }

    @Published var isStackPresented = false
    @Published var stackIndex = 0
    @Published var openedStackPostcardIds: [String] = []
    @Published var selectedPostcard: Postcard?
    @Published private(set) var selectedPostcardSource: PostcardDetailSource?
    @Published private(set) var pendingReadPostcardId: String?
    @Published var isHistoryPresented = false

    func openStack(with postcards: [Postcard]) {
        guard postcards.isEmpty == false else { return }
        openedStackPostcardIds = postcards.map(\.id)
        stackIndex = 0
        isStackPresented = true
    }

    func closeStack(repository: AppRepository? = nil) {
        if let repository {
            markOpenedStackPostcardsRead(repository: repository)
        }
        isStackPresented = false
        stackIndex = 0
        openedStackPostcardIds = []
    }

    func showPreviousPostcard(count: Int) {
        guard count > 1 else { return }
        stackIndex = max(stackIndex - 1, 0)
    }

    func showNextPostcard(count: Int) {
        guard count > 1 else { return }
        stackIndex = min(stackIndex + 1, count - 1)
    }

    func showUnreadStackDetail(_ postcard: Postcard) {
        selectedPostcard = postcard
        selectedPostcardSource = .unreadStack
        pendingReadPostcardId = postcard.id
    }

    func showHistoryDetail(_ postcard: Postcard) {
        selectedPostcard = postcard
        selectedPostcardSource = .history
        pendingReadPostcardId = nil
    }

    func settleSelectedPostcardDismissal(repository: AppRepository) {
        defer {
            selectedPostcard = nil
            selectedPostcardSource = nil
            pendingReadPostcardId = nil
        }

        guard selectedPostcardSource == .unreadStack,
              let pendingReadPostcardId,
              let postcard = repository.postcards.first(where: { $0.id == pendingReadPostcardId }) else {
            return
        }

        repository.markPostcardRead(postcard)
        openedStackPostcardIds.removeAll { $0 == pendingReadPostcardId }

        if openedStackPostcardIds.isEmpty {
            closeStack()
        } else {
            stackIndex = min(stackIndex, openedStackPostcardIds.count - 1)
        }
    }

    private func markOpenedStackPostcardsRead(repository: AppRepository) {
        for postcardId in openedStackPostcardIds {
            guard let postcard = repository.postcards.first(where: { $0.id == postcardId }) else { continue }
            repository.markPostcardRead(postcard)
        }
    }
}
