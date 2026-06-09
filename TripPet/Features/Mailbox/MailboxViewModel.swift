import Combine
import Foundation

@MainActor
final class MailboxViewModel: ObservableObject {
    @Published var selectedPostcard: Postcard?

    func open(_ postcard: Postcard, repository: AppRepository) {
        repository.markPostcardRead(postcard)
        selectedPostcard = repository.postcards.first { $0.id == postcard.id } ?? postcard
    }
}
