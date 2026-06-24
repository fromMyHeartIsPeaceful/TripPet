import Combine
import Foundation

@MainActor
final class MailboxViewModel: ObservableObject {
    @Published var selectedPostcard: Postcard?

    func open(_ postcard: Postcard, repository: AppRepository) {
        selectedPostcard = postcard
        Task { @MainActor in
            await Task.yield()
            repository.markPostcardRead(postcard)
        }
    }
}
