import SwiftUI
import SwiftUIPager

// TODO: Implement other shapes
struct LikeDislikeRatingButton: View {
    @ObservedObject var entryVM: EntriesViewModel
    @State var rating: Bool?
    @State var serviceKey: String
    @State var hash: String
    @State var entryId: Int
    
    private func newRating() -> Bool? {
        switch rating {
        case nil:
            true
        case true:
            false
        case false:
            nil
        default:
            nil
        }
    }
    
    var body: some View {
        // FIXME: Does not update after pressing the button
        Button(action: {
            let newValue = newRating()
            
            let srr = SetRatingRequest(hash: hash, ratingServiceKey: serviceKey, rating: newValue == nil ? RatingValue.null : RatingValue.boolean(newValue!), hydrusApiKey: nil)
            
            entryVM.setRatingWrapper(hash: hash, service: serviceKey, setRatingRequest: srr) { success in
                entryVM.fetchMetadata(entryId: entryId)
            }
        }, label: {
            switch rating {
            case nil:
                Image(systemName: "star")
            case true:
                Image(systemName: "star.fill")
            case false:
                Image(systemName: "star.slash")
            default:
                EmptyView()
            }
        })
    }
}

// TODO: Edit tags
private struct InspectorView: View {
    @ObservedObject var entryVM: EntriesViewModel
    @SceneStorage("isFileInfoExpanded") var isFileInfoExpanded = true
    @SceneStorage("isRatingExpanded") var isRatingExpanded = true
    @SceneStorage("isKnownUrlsExpanded") var isKnownUrlsExpanded = true
    @SceneStorage("isAllKnownTagsExpanded") var isAllKnownTagsExpanded = true

    @Binding var pageIndex: Int
    
    private func boolToYesNo(val: Bool) -> String {
        switch val {
        case true:
            "yes"
        case false:
            "no"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                let entry = entryVM.entries.values[pageIndex]
                DisclosureGroup(isExpanded: $isRatingExpanded, content: {
                    ForEach(Array(entry.metadata.ratings.keys), id: \.self) { key in
                        HStack {
                            Text("\(entryVM.services[key]!.name)")
                            switch entryVM.services[key]!.type {
                            case .LikeDislikeRating:
                                LikeDislikeRatingButton(entryVM: entryVM, rating: entry.metadata.ratings[key]!?.booleanValue, serviceKey: key, hash: entry.metadata.hash, entryId: entry.metadata.fileId)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }, label: {
                    Text("Rating").font(.headline)
                        .onTapGesture {
                            isRatingExpanded.toggle()
                        }
                })
                .padding(.horizontal, 10)
                DisclosureGroup(isExpanded: $isFileInfoExpanded, content: {
                    let size = ByteCountFormatter().string(fromByteCount: Int64(entry.metadata.size))
                    let fileType = entry.metadata.filetypeHuman
                    let hash = entry.metadata.hash
                    Text(hash)
                    Text("Size: \(size)")
                    Text("Filetype: \(fileType)")
                    if let width = entry.metadata.width {
                        if let height = entry.metadata.height {
                            Text("Resolution: \(String(width)) x \(String(height))")
                        }
                    }
                    Text("Has audio: " + boolToYesNo(val: entry.metadata.hasAudio))
                }, label: {
                    Text("File Info").font(.headline)
                        .onTapGesture {
                            isFileInfoExpanded.toggle()
                        }
                })
                .padding(.horizontal, 10)
                if let knownUrls = entry.metadata.knownUrls {
                    DisclosureGroup(isExpanded: $isKnownUrlsExpanded, content: {
                        ForEach(knownUrls, id: \.self) { url in
                            Link(url, destination: URL(string: url)!)
                        }
                    }, label: {
                        Text("Known URLs").font(.headline)
                            .onTapGesture {
                                isKnownUrlsExpanded.toggle()
                            }
                    })
                    .padding(.horizontal, 10)
                }
                
                if let allKnownTagsService = entryVM.services.first(where: { $0.value.type == .AllKnownTags }) {
                    TagSectionView(entryVM: entryVM, expanded: true /*$isAllKnownTagsExpanded*/, tags: entry.metadata.tags[allKnownTagsService.key]!.displayTags["0"]!, service: allKnownTagsService.value.name)
                        .id(UUID())
                        .padding(.horizontal, 10)
                }
            }
        }
        .textSelection(.enabled)
    }
}

private struct EntryMediaView: View {
    @State var entry: Entry
    @State var isPlaying = false
    
    private func isVideo(entry: Entry) -> Bool {
        if entry.metadata.duration != nil {
            return true
        }
        return false
    }
    
    
    var body: some View {
        if isVideo(entry: entry) {
            EntryVideoView(url: entry.downloadUrl!)
                .onAppear {
                    print(String(entry.id) + " " + entry.metadata.ext)
                }
        } else {
            EntryImageView(url: entry.downloadUrl!, blurHash: entry.metadata.blurhash!, size: CGSize(width: entry.metadata.width!, height: entry.metadata.height!)) // FIXME: May crash
        }
    }
}

struct EntryDetailsView: View {
    @ObservedObject var viewModel: EntriesViewModel
    @StateObject var page: Page
    @SceneStorage("showInspector") private var showInspector = false
    
    private func openInExternalProgram() {
        let entry = Array(viewModel.entries.values)[page.index]
        downloadFile(from: entry.downloadUrl!, moveToDownloads: false, customFileName: entry.metadata.hash + entry.metadata.ext) { url, error in
            if let url = url {
                print(url)
                NSWorkspace.shared.open(url)
            } else {
                print(error)
            }
        }
    }
    
    private func downloadEntry() {
        let entry = Array(viewModel.entries.values)[page.index]
        downloadFile(from: entry.downloadUrl!, moveToDownloads: true, customFileName: entry.metadata.hash + entry.metadata.ext) { _,_ in
            print("Downlajfioajwof")
        }
    }
    
    var body: some View {
        VStack {
            Pager(page: page,
                  data: viewModel.entries.values,
                  content: { entry in
                EntryMediaView(entry: entry)
            })
            .contentLoadingPolicy(.lazy(recyclingRatio: 0))
            .disableDragging()
            .onReceive(NotificationCenter.default.publisher(for: .previousEntryNotification), perform: { _ in
                page.update(.previous)
            })
            .onReceive(NotificationCenter.default.publisher(for: .nextEntryNotification), perform: { _ in
                page.update(.next)
            })
            .inspector(isPresented: $showInspector) {
                InspectorView(entryVM: viewModel, pageIndex: $page.index)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        downloadEntry()
                    } label: {
                        Image(systemName: "icloud.and.arrow.down").foregroundColor(.accentColor)
                    }.help("Download File")
                }
                ToolbarItem {
                    Button {
                        openInExternalProgram()
                    } label: {
                        Image(systemName: "macwindow").foregroundColor(.accentColor)
                    }.help("Open in external program")
                }
                ToolbarItem {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Image(systemName: "info.circle").foregroundColor(.accentColor)
                    }.help("Toggle Inspector")
                }
            }
        }
    }
}
