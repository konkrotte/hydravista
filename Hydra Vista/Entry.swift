import Foundation

class Entry: Identifiable, ObservableObject, Codable {
    let id: Int
    let thumbnailUrl: URL?
    let downloadUrl: URL?
    let renderUrl: URL?
    @Published var metadata: FileMetadata
    
    enum CodingKeys: CodingKey {
        case id
        case thumbnailUrl
        case downloadUrl
        case renderurl
        case metadata
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        thumbnailUrl = try container.decode(URL?.self, forKey: .thumbnailUrl)
        downloadUrl = try container.decode(URL?.self, forKey: .downloadUrl)
        renderUrl = try container.decode(URL?.self, forKey: .renderurl)
        metadata = try container.decode(FileMetadata.self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(downloadUrl, forKey: .downloadUrl)
        try container.encode(renderUrl, forKey: .renderurl)
        try container.encode(metadata, forKey: .metadata)

    }
    
    init(id: Int, thumbnailUrl: URL?, downloadUrl: URL?, renderUrl: URL?, metadata: FileMetadata) {
        self.id = id
        self.thumbnailUrl = thumbnailUrl
        self.downloadUrl = downloadUrl
        self.metadata = metadata
        self.renderUrl = renderUrl
    }
}

extension Entry: Hashable {
    static func == (lhs: Entry, rhs: Entry) -> Bool {
        lhs.id == rhs.id
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
