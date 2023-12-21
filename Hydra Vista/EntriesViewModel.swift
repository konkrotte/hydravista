import Foundation
import SwiftUI
import OrderedCollections

@MainActor
final class EntriesViewModel : ObservableObject {
    @Published var entries: OrderedDictionary<Int, Entry> = [:]
    @Published var search: Set<String> = []
    @Published var services: [String: Service] = [:]
    @Published var isFetching = false
    @Published var sortType = FileSortType.FileSize
    @Published var sortAsc = false
    @Published var topTags: OrderedDictionary<String, Int> = [:]
    @Published var selectedFileDomains: Set<String> = []
    
    let delay: TimeInterval = 0.5
    private var task: Task<Void, Never>?
    private var dataIndexed = false
    
    @AppStorage("remoteHostname") private var remoteHostname = "127.0.0.1"
    @AppStorage("remotePort") private var remotePort = "45869"
    @AppStorage("remoteUseHttps") private var remoteUseHttps = false
    @AppStorage("remoteApiKey") private var remoteApiKey = ""
    @AppStorage("defaultSearch") private var defaultSearch = "rating:safe"
    @AppStorage("defaultSortType") private var defaultSortType = FileSortType.FileSize
    @AppStorage("defaultSortAsc") private var defaultSortAsc = false
    
    
    init() {
        self.entries.reserveCapacity(100)
        self.search.update(with: defaultSearch)
        self.sortType = defaultSortType
        self.sortAsc = defaultSortAsc
    }
    
    func setRatingWrapper(hash: String, service: String, setRatingRequest: SetRatingRequest, completion: @escaping (Bool) -> Void) {
        var url = URLComponents()
        url.host = self.remoteHostname
        url.scheme = self.remoteUseHttps ? "https" : "http"
        url.port = Int(self.remotePort)
        
        setRating(url: url, apiKey: self.remoteApiKey, setRatingRequest: setRatingRequest, completion: { val in
            completion(val!)
        })
    }
    
    func searchTagsWrapper(search: String, completion: @escaping (TagSearchResponse?) -> Void) {
        var url = URLComponents()
        url.host = self.remoteHostname
        url.scheme = self.remoteUseHttps ? "https" : "http"
        url.port = Int(self.remotePort)
        
        searchTags(url: url, apiKey: self.remoteApiKey, search: search, completion: { tsr in
            completion(tsr)
        })
    }
    
    func fetchMetadata(entryId: Int) {
        var url = URLComponents()
        url.host = self.remoteHostname
        url.scheme = self.remoteUseHttps ? "https" : "http"
        url.port = Int(self.remotePort)
        
        // FIXME: lol
        getFileMetadata(url: url, apiKey: self.remoteApiKey, fileIds: [entryId]) { fmr in
            self.entries[(fmr!.metadata[0].fileId)]?.metadata = (fmr?.metadata[0])!
        }
    }

    func fetchEntries() {
        task?.cancel()
        task = Task {
            await Task.sleep(UInt64(delay * 1_000_000_000.0))
            
            guard !Task.isCancelled else {
                return
            }
            
            self.isFetching = true
            var entries: OrderedDictionary<Int, Entry> = [:]
            let fsq = FileSearchQuery.init(tags: Array(self.search), fileDomains: Array(self.selectedFileDomains), tagServiceKeys: nil, fileSortType: self.sortType, fileSortAsc: self.sortAsc, returnFileIds: nil, returnHashes: nil)
            var url = URLComponents()
            url.host = self.remoteHostname
            url.scheme = self.remoteUseHttps ? "https" : "http"
            url.port = Int(self.remotePort)
            
            var fileIds: [Int] = []
            
            searchFiles(url: url, apiKey: self.remoteApiKey, fileSearchQuery: fsq, completion: { fsr in
                fileIds = fsr?.fileIds ?? []
                getFileMetadata(url: url, apiKey: self.remoteApiKey, fileIds: fileIds) { fmr in
                    if let metadatas = fmr?.metadata {
                        for e in metadatas {
                            var thumbnailUrl = getThumbnailUrl(url: url, apiKey: self.remoteApiKey, fileId: e.fileId)
                            var downloadUrl = getFileDownloadUrl(url: url, apiKey: self.remoteApiKey, fileId: e.fileId)
                            var renderUrl = getRenderUrl(url: url, apiKey: self.remoteApiKey, fileId: e.fileId)
                            
                            entries.updateValue(Entry.init(id: e.fileId, thumbnailUrl: thumbnailUrl, downloadUrl: downloadUrl, renderUrl: renderUrl, metadata: e), forKey: e.fileId)
                        }
                    }
                    
                    self.task?.cancel()
                    self.task = Task {
                        await Task.sleep(UInt64(self.delay * 1_000_000_000.0))
                        
                        guard !Task.isCancelled else {
                            return
                        }
                        
                        guard fsq.tags == Array(self.search) else {
                            return
                        }
                        
                        if let servicesToMerge = fmr?.services {
                            self.services.merge(servicesToMerge) { _, new in
                                new
                            }
                        }
                        
                        var tagSet: CountedSet<String> = []
                        
                        for entry in entries.values {
                            for tagService in entry.metadata.tags.values {
                                for tags in tagService.displayTags.values {
                                    for tag in tags {
                                        tagSet.insert(tag)
                                    }
                                }
                            }
                        }
                        
                        let tags = OrderedDictionary(uniqueKeysWithValues: Array(tagSet.elements.sorted(by: { $0.value > $1.value }).prefix(10)))
                        
                        self.topTags = tags
                        self.entries = entries
                        self.isFetching = false
                    }
                }
            })
        }
    }
}
