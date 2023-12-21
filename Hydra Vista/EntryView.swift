import SwiftUI
import NukeUI
import UnifiedBlurHash

struct EntryView: View {
    @State var entry: Entry
    
    @AppStorage("remoteHostname") private var remoteHostname = "127.0.0.1"
    @AppStorage("remotePort") private var remotePort = "45869"
    @AppStorage("remoteUseHttps") private var remoteUseHttps = false
    @AppStorage("remoteApiKey") private var remoteApiKey = ""
    
    @Sendable
    func loadFileForItemProvider(onComplete callback: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)

        Task.detached {
            do {
                let temporaryDirectory = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: .documentsDirectory, create: true)
                let url = temporaryDirectory.appendingPathComponent(entry.metadata.hash + entry.metadata.ext)
                try Data().write(to: url)
                let handle = try FileHandle(forWritingTo: url)
                callback(url.dataRepresentation, nil)
                guard let downloadUrl = entry.downloadUrl else {
                    try? handle.close()
                    return
                }
                let (fileData, _) = try await URLSession.shared.data(from: downloadUrl)
                try handle.write(contentsOf: fileData)
                try? handle.close()
                progress.completedUnitCount = 100
            } catch {
                callback(nil, error)
            }
        }

        return progress
    }
    
    var body: some View {
        NavigationLink(value: entry.id) {
            LazyImage(url: entry.thumbnailUrl) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                } else if state.error != nil {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                } else {
                    if let blurHash = entry.metadata.blurhash {
                        Image(blurHash: blurHash)!
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    }
                }
            }
        }
        .disabled(true)
        .contextMenu(ContextMenu(menuItems: {
            Button(action: {
                var url = URLComponents()
                url.host = remoteHostname
                url.scheme = remoteUseHttps ? "https" : "http"
                url.port = Int(remotePort)
                
                let fileURL = getFileDownloadUrl(url: url, apiKey: remoteApiKey, fileId: entry.id)!
                downloadFile(from: fileURL, moveToDownloads: true, customFileName: entry.metadata.hash + entry.metadata.ext) { (localURL, error) in
                    if let localURL = localURL {
                        print("Downloaded file is saved at: \(localURL.path)")
                    } else if let error = error {
                        print("Error downloading file: \(error)")
                    }
                }
            }, label: {
                Text("Download")
            })
        }))
        .onDrag {
            let provider = NSItemProvider()
            provider.registerDataRepresentation(for: .fileURL, visibility: .all, loadHandler: loadFileForItemProvider)
            return provider
        }
        .frame(width: 150, height: 150)
    }
}
