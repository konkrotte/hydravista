import SwiftUI
import SwiftUIX
import OrderedCollections
import SwiftUIPager
import NukeUI

struct SearchView: View {
    @ObservedObject public var vm: EntriesViewModel
    @SceneStorage("showInspector") private var showInspector = false
    @SceneStorage("SearchView.SearchPersist") private var searchPersist = Data()
    @SceneStorage("SearchView.IdPersist") private var idPersist: Int?
    @State var path = [Int]()
    
    let layout = [
        GridItem(.adaptive(minimum: 115)),
    ]
    
    var body: some View {
        NavigationStack(path: $path) {
            if vm.isFetching {
                ActivityIndicator()
                    .animated(true)
            } else {
                ScrollView {
                    LazyVGrid(columns: layout) {
                        ForEach(Array(vm.entries.values)) { entry in
                            EntryView(entry: entry/*, viewModel: vm*/)
                                .id(entry.id)
                            // FIXME: ScrollView loses position, doesn't happen when a NavigationLink handles the tap gesture directly
                                .onTapGesture {
                                    self.path = [entry.id]
                                }
                        }
                    }
                    // TODO: Open entry in new tab
                    .navigationDestination(for: Int.self) { entryId in
                        EntryDetailsView(viewModel: vm, page: Page.withIndex(vm.entries.index(forKey: entryId)!))
                    }
                    .padding(.horizontal)
                    .padding()
                }
                .listStyle(.plain)
                .refreshable {
                    vm.fetchEntries()
                }
                .id(UUID())
            }
        }
        .onAppear {
            let decoder = JSONDecoder()
            
            if let search = try? decoder.decode(Set<String>.self, from: searchPersist) {
                vm.search = search
            }
            
            if vm.entries.isEmpty {
                vm.fetchEntries()
            }
            
            if let id = idPersist {
                print(id)
                // TODO: Do something with id
            }
        }
        .onChange(of: vm.search) {
            let encoder = JSONEncoder()
            
            if let data = try? encoder.encode(vm.search) {
                searchPersist = data
            }
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(topTags: $vm.topTags, entryVM: vm)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInspector.toggle()
                } label: {
                    Image(systemName: "info.circle") .foregroundColor(.accentColor)
                }.help("Toggle Inspector")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshNotification)) { _ in
            vm.fetchEntries()
        }
    }
}

struct SearchSideView: View {
    @ObservedObject var autocomplete: AutocompleteObject
    @ObservedObject public var entryVM: EntriesViewModel
    @SceneStorage("SearchSideView.TagEntry") private var tagEntry = ""
    @FocusState private var isFieldFocused: Bool
    @State private var isPopoverShown = false
    @State private var selectedTags = Set<String>()
    @SceneStorage("SearchSideView.SortAsc") private var persistSortAsc: Bool?
    @SceneStorage("SearchSideView.SortType") private var persistSortType: FileSortType?
    
    func delete(at offsets: IndexSet) {
        var array = Array(entryVM.search)
        array.remove(atOffsets: offsets)
        entryVM.search = Set(array)
    }
    
    var body: some View {
        // TODO: Display relevant information in each entryview
        // For example, sorting by file size should display the file size of each entry
        Picker("Sort", selection: $entryVM.sortType) {
            ForEach(FileSortType.allCases) { sortType in
                Text(sortType.label)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: entryVM.sortType) {
            entryVM.fetchEntries()
            persistSortType = entryVM.sortType
        }
        .onAppear {
            if let sortType = persistSortType {
                entryVM.sortType = sortType
            }
        }
        Toggle(isOn: $entryVM.sortAsc) {
            Text("Ascending?")
        }
        .onChange(of: entryVM.sortAsc) {
            entryVM.fetchEntries()
            persistSortAsc = entryVM.sortAsc
        }
        .onAppear {
            if let val = persistSortAsc {
                entryVM.sortAsc = val
            }
        }
        TextField("Enter tag", text: $tagEntry)
        .onReceive(NotificationCenter.default.publisher(for: .searchNotification), perform: { _ in
            isFieldFocused = true
        })
        .onChange(of: tagEntry) {
            if !tagEntry.isEmpty {
                autocomplete.autocomplete(tagEntry)
            } else {
                isPopoverShown = false
            }
        }
        .onChange(of: autocomplete.suggestions) {
            if autocomplete.suggestions.isEmpty {
                isPopoverShown = false
            } else {
                isPopoverShown = true
            }
        }
        .popover(isPresented: $isPopoverShown, arrowEdge: .bottom) {
            if !autocomplete.isWorking {
                ForEach(autocomplete.suggestions.prefix(5), id: \.self) { tag in
                    Text("\(tag.value): \(tag.count)")
                        .onTapGesture {
                            entryVM.search.insert(tag.value)
                            tagEntry = ""
                            entryVM.fetchEntries()
                        }
                        .frame(width: 300)
                }
            } else {
                ActivityIndicator()
                    .animated(true)
            }
        }
        .textFieldStyle(.roundedBorder)
        .focused($isFieldFocused)
        .onSubmit {
            entryVM.search.update(with: tagEntry)
            tagEntry = ""
            entryVM.fetchEntries()
        }
        .navigationTitle(entryVM.search.first ?? "Search")
        VStack(alignment: .leading) {
            Text("Query").font(.headline)
            List(selection: $selectedTags) {
                ForEach(Array(entryVM.search), id: \.self) { tag in
                    Text(tag)
                        .draggable(tag)
                }
                .onDelete(perform: delete)
            }
            .contextMenu(forSelectionType: String.self) { items in
                Button(action: {
                    if !items.isEmpty {
                        for item in items {
                            entryVM.search.remove(item)
                        }
                        entryVM.fetchEntries()
                    }
                }, label: {
                    Text("Remove")
                })
            } primaryAction: { items in
                if !items.isEmpty {
                    for item in items {
                        entryVM.search.remove(item)
                    }
                    entryVM.fetchEntries()
                }
            }
            .cuttable(for: String.self) {
                if !selectedTags.isEmpty {
                    for item in selectedTags {
                        entryVM.search.remove(item)
                    }
                    entryVM.fetchEntries()
                }
                
                return Array(selectedTags)
            }
            .copyable(Array(selectedTags))
            .onDeleteCommand {
                if !selectedTags.isEmpty {
                    for tag in selectedTags {
                        entryVM.search.remove(tag)
                    }
                    
                    entryVM.fetchEntries()
                }
            }
            .frame(height: 200)
            .background(.secondarySystemBackground)
            .cornerRadius(10)
        }
        VStack(alignment: .leading) {
            Text("File domains").font(.headline)
            List(Array(entryVM.services.keys).sorted(), id: \.self, selection: $entryVM.selectedFileDomains) { serviceKey in
                if let service = entryVM.services[serviceKey] {
                    if (service.type == .LocalFileDomain) {
                        Text(service.name)
                            .onTapGesture(perform: {
                                if entryVM.selectedFileDomains.contains(serviceKey) {
                                    entryVM.selectedFileDomains.remove(serviceKey)
                                } else {
                                    entryVM.selectedFileDomains.insert(serviceKey)
                                }
                            })
                    }
                }
            }
            .onChange(of: entryVM.selectedFileDomains, {
                entryVM.fetchEntries()
            })
            .frame(height: 200)
            .background(.secondarySystemBackground)
            .cornerRadius(10)
        }
    }
}

private struct InspectorView: View {
    @Binding var topTags: OrderedDictionary<String, Int>
    @SceneStorage("isTopTagsExpanded") var isTopTagsExpanded = true
    @ObservedObject var entryVM: EntriesViewModel
    
    var body: some View {
        ScrollView {
            Text("Found: \(entryVM.entries.count)")
            DisclosureGroup(isExpanded: $isTopTagsExpanded, content: {
                VStack {
                    ForEach(Array(topTags.keys), id: \.self) { tag in
                        TagView(tag: tag, exclude: { tag in
                            entryVM.search.update(with: "-\(tag)")
                            entryVM.fetchEntries()
                        }, add: { tag in
                            entryVM.search.update(with: tag)
                            entryVM.fetchEntries()
                        })
                    }
                }
            }, label: {
                Text("Top tags").font(.headline)
            })
            .padding(.horizontal, 20)
        }
    }
}

