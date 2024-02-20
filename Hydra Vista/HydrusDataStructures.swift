import Foundation

enum ServiceType: Int, Codable {
    case TagRepository = 0
    case FileRepository = 1
    case LocalFileDomain = 2
    case LocalTagDomain = 5
    case NumericalRating = 6
    case LikeDislikeRating = 7
    case AllKnownTags = 10
    case AllKnownFiles = 11
    case Ipfs = 13
    case Trash = 14
    case AllLocalFiles = 15
    case FileNotes = 17
    case ClientApi = 18
    case RepositoryUpdates = 20
    case AllMyFiles = 21
    case IncDecRating = 22
    case ServerAdministration = 99
}

enum FileSortType: Int, Codable, CaseIterable, Identifiable {
    case FileSize = 0
    case Duration = 1
    case ImportTime = 2
    case FileType = 3
    case Random = 4
    case Width = 5
    case Height = 6
    case Ratio = 7
    case NumberOfPixels = 8
    case NumberOfTags = 9
    case NumberOfMediaViews = 10
    case TotalMediaViewtime = 11
    case ApproximateBitrate = 12
    case HasAudio = 13
    case ModifiedTime = 14
    case Framerate = 15
    case NumberOfFrames = 16
    case LastViewedTime = 18
    case ArchiveTimestamp = 19
    case HashHex = 20
    
    var id: FileSortType { self }
    
    var label: String {
        switch self {
        case .FileSize:
            return "File Size"
        case .Duration:
            return "Duration"
        case .Random:
            return "Random"
        case .ApproximateBitrate:
            return "Approximate bitrate"
        case .ArchiveTimestamp:
            return "Archive Timestamp"
        case .FileType:
            return "File Type"
        case .Framerate:
            return "Framerate"
        case .HasAudio:
            return "Has Audio"
        case .HashHex:
            return "Hash Hex"
        case .Height:
            return "Height"
        case .ImportTime:
            return "Import Time"
        case .LastViewedTime:
            return "Last Viewed Time"
        case .ModifiedTime:
            return "Last Modified Time"
        case .NumberOfFrames:
            return "Number of Frames"
        case .NumberOfTags:
            return "Number of Tags"
        case .NumberOfMediaViews:
            return "Number of Media Views"
        case .NumberOfPixels:
            return "Number of Pixels"
        case .Ratio:
            return "Ratio"
        case .TotalMediaViewtime:
            return "Total Media Viewtime"
        case .Width:
            return "Width"
        }
    }
}

struct Service: Codable {
    let name: String
    let type: ServiceType
    let typePretty: String
    let star_shape: String?
}

struct FileSearchQuery: Codable {
    let tags: [String]
    let fileDomains: [String]
    let tagServiceKeys: String?
    let fileSortType: FileSortType
    let fileSortAsc: Bool
    let returnFileIds: Bool?
    let returnHashes: Bool?
}

struct FileSearchResponse: Codable {
    let fileIds: [Int]
    let version: Int
    let hydrusVersion: Int
}

struct FileService: Codable {
    let name: String
    let type: ServiceType
    let typePretty: String
    let timeImported: TimeInterval
}

struct FileServices:Codable{
    let current:[String: FileService]
    let deleted:[String: FileService]
}

struct Tags:Codable{
    let storageTags:[String:[String]]
    let displayTags:[String:[String]]
}

enum RatingValue: Codable {
    case integer(Int)
    case boolean(Bool)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        
        if let x = try? container.decode(Bool.self) {
            self = .boolean(x)
            return
        }
        
        throw DecodingError.typeMismatch(RatingValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .boolean(let x):
            try container.encode(x)
        }
    }
    
    var intValue: Int {
        switch self {
        case .integer(let s):
            return s
        default:
            return 0
        }
    }
    
    var booleanValue: Bool {
        switch self {
        case .boolean(let s):
            return s
        case .integer(let s):
            return s == 1
        }
    }
}

struct FileMetadata: Codable {
    let fileId: Int
    let hash, mime, filetypeHuman, ext: String
    let filetypeEnum: Int
    let width, height: Int?
    let thumbnailWidth, thumbnailHeight: Int?
    let duration: TimeInterval?
    let timeModified: TimeInterval
    let size: Int
    let timeModifiedDetails: [String: TimeInterval]
    let fileServices: FileServices
    let ipfsMultihashes: [String: String]?
    let hasAudio: Bool
    let blurhash: String?
    let pixelHash: String?
    let numFrames, numWords: Int?
    let isInbox, isLocal, isTrashed, isDeleted: Bool
    let hasExif , hasHumanReadableEmbeddedMetadata , hasIccProfile: Bool
    let hasTransparency: Bool?
    let knownUrls: [String]?
    let ratings : [String:RatingValue?]
    let tags : [String : Tags]
}

struct FileMetadataResponse: Codable {
    let services: [String: Service]?
    let metadata: [FileMetadata]
    let version: Int
    let hydrusVersion: Int
}

struct EditTagsRequest: Codable {
    let fileIds: [Int]
    let serviceKeysToActionsToTags: [String: [String: [String]]]
    let hydrusApiKey: String?
    
    enum CodingKeys: String, CodingKey {
        case hydrusApiKey = "Hydrus-Client-API-Access-Key"
        case fileIds = "file_ids"
        case serviceKeysToActionsToTags = "service_keys_to_actions_to_tags"
    }
}

struct Tag: Codable, Hashable {
    let value: String
    let count: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

struct TagSearchResponse: Codable {
    let tags: [Tag]
}

struct SetRatingRequest: Codable {
    let hash: String
    let ratingServiceKey: String
    let rating: RatingValue?
    let hydrusApiKey: String?
    
    enum CodingKeys: String, CodingKey {
        case hash
        case ratingServiceKey = "rating_service_key"
        case rating
        case hydrusApiKey = "Hydrus-Client-API-Access-Key"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hash, forKey: .hash)
        try container.encode(ratingServiceKey, forKey: .ratingServiceKey)
        try container.encode(rating, forKey: .rating)
        try container.encode(hydrusApiKey, forKey: .hydrusApiKey)
    }
}
