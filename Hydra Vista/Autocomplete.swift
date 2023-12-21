import SwiftUI

@MainActor
final class AutocompleteObject: ObservableObject {
    @ObservedObject var entryVM: EntriesViewModel
    
    let delay: TimeInterval = 0.3
    
    @Published var suggestions: [Tag] = []
    @Published var isWorking = false
    
    init(entryVM: EntriesViewModel) {
        self.entryVM = entryVM
    }
    
    private var task: Task<Void, Never>?
    
    func autocomplete(_ text: String) {
        guard !text.isEmpty else {
            suggestions = []
            task?.cancel()
            return
        }
        
        task?.cancel()
        
        task = Task {
            isWorking = true
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
            } catch {}
            
            guard !Task.isCancelled else {
                return
            }
            
            entryVM.searchTagsWrapper(search: text) { tsr in
                self.suggestions = tsr?.tags ?? []
                
                self.isWorking = false
            }
        }
    }
}
