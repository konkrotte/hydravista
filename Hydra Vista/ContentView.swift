import SwiftUI
import SwiftUIX
import NukeUI
import SwiftUIPager
import OrderedCollections

class AppViewModel: ObservableObject {
    @Published var entriesVM: EntriesViewModel
    
    init(entriesVM: EntriesViewModel) {
        self.entriesVM = entriesVM
    }
}

struct ContentView: View {
    @SceneStorage("ContentView.selectedNav") var selectedNav: String?
    var navs = ["Search"]
    @StateObject var appVM = AppViewModel(entriesVM: EntriesViewModel())
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNav) {
                Section(header: Text("Menu")) {
                    ForEach(navs, id: \.self) { nav in
                        NavigationLink(value: nav) {
                            Label(nav, systemImage: nav == "Search" ? "magnifyingglass" : "heart")
                        }
                        .tag(nav)
                    }
                }
                if selectedNav == "Search" {
                    Section(header: Text("Search")) {
                        SearchSideView(autocomplete: AutocompleteObject(entryVM: appVM.entriesVM), entryVM: appVM.entriesVM)
                    }
                }
            }
        } detail: {
            if selectedNav == "Search" {
                SearchView(vm: appVM.entriesVM)
            } else {
                Text("Select an option in the sidebar")
            }
        }
    }
}

#Preview {
    ContentView()
}
