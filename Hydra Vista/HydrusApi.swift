import Foundation

func searchFiles(url: URLComponents, apiKey: String, fileSearchQuery: FileSearchQuery, completion: @escaping (FileSearchResponse?) -> Void) {
    var url = url
    url.path = "/get_files/search_files"
    
    let encoder = JSONEncoder()
    guard let jsonData = try? encoder.encode(fileSearchQuery.tags) else {
        print("Could not encode FileSearchQuery to JSON")
        completion(nil)
        return
    }
    
    guard let encodedTags = String(data: jsonData, encoding: .utf8) else {
        print("Could not encode FileSearchQuery to String")
        completion(nil)
        return
    }
    
    guard let jsonData = try? encoder.encode(fileSearchQuery.fileDomains) else {
        print("Could not encode FileSearchQuery to JSON")
        completion(nil)
        return
    }
    
    guard let encodedFileServiceKeys = String(data: jsonData, encoding: .utf8) else {
        print("Could not encode FileSearchQuery to String")
        completion(nil)
        return
    }
    
    url.queryItems = [
        URLQueryItem(name: "tags", value: encodedTags),
        URLQueryItem(name: "file_sort_type", value: String(fileSearchQuery.fileSortType.rawValue)),
        URLQueryItem(name: "file_sort_asc", value: fileSearchQuery.fileSortAsc ? "true" : "false"),
        URLQueryItem(name: "file_service_keys", value: encodedFileServiceKeys),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalUrl = url.url else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    URLSession.shared.dataTask(with: finalUrl) { data, response, error in
        if let error = error {
            print(error)
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("Error!")
            completion(nil)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(FileSearchResponse.self, from: data)
            completion(result)
        } catch {
            print(error)
            completion(nil)
        }
    }.resume()
}

func getFileMetadata(url: URLComponents, apiKey: String, fileIds: [Int], completion: @escaping (FileMetadataResponse?) -> Void) {
    var url = url
    url.path = "/get_files/file_metadata"
    
    let encoder = JSONEncoder()
    guard let jsonData = try? encoder.encode(fileIds) else {
        print("Could not encode FileIds to JSON")
        completion(nil)
        return
    }
    
    guard let encodedFileIds = String(data: jsonData, encoding: .utf8) else {
        print("Could not encode FileIds to String")
        completion(nil)
        return
    }
    
    url.queryItems = [
        URLQueryItem(name: "file_ids", value: encodedFileIds),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalUrl = url.url else {
        print("Invalid URL")
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: finalUrl) { data, response, error in
        if let error = error {
            print("URLSession data task failed with error: \(error)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data returned from server")
            completion(nil)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(FileMetadataResponse.self, from: data)
            completion(result)
            
        } catch {
            print(error)
            if let string = String(bytes: data, encoding: .utf8)  {
                print(string)
            }
            completion(nil)
        }
    }.resume()
}

func getThumbnailUrl(url: URLComponents, apiKey: String, fileId: Int) -> URL? {
    var url = url
    url.path = "/get_files/thumbnail"
    url.queryItems = [
        URLQueryItem(name: "file_id", value: String(fileId)),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalThumbnaillUrl = url.url else {
        return nil
    }
    
    return finalThumbnaillUrl
}

func getRenderUrl(url: URLComponents, apiKey: String, fileId: Int) -> URL? {
    var url = url
    url.path = "/get_files/render"
    url.queryItems = [
        URLQueryItem(name: "file_id", value: String(fileId)),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalThumbnaillUrl = url.url else {
        return nil
    }
    
    return finalThumbnaillUrl
}

func getFileDownloadUrl(url: URLComponents, apiKey: String, fileId: Int) -> URL? {
    var url = url
    url.path = "/get_files/file"
    url.queryItems = [
        URLQueryItem(name: "file_id", value: String(fileId)),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalDownloadlUrl = url.url else {
        return nil
    }
    
    return finalDownloadlUrl
}

func searchTags(url: URLComponents, apiKey: String, search: String, completion: @escaping (TagSearchResponse?) -> Void) {
    completion(nil)
    var url = url
    url.path = "/add_tags/search_tags"

    url.queryItems = [
        URLQueryItem(name: "search", value: search),
        URLQueryItem(name: "Hydrus-Client-API-Access-Key", value: apiKey),
    ]
    
    guard let finalUrl = url.url else {
        completion(nil)
        return
    }
        
    URLSession.shared.dataTask(with: finalUrl) { data, response, error in
        if let error = error {
            print("URLSession data task failed with error: \(error)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data returned from server")
            completion(nil)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(TagSearchResponse.self, from: data)
            completion(result)
            
        } catch {
            print(error)
            if let string = String(bytes: data, encoding: .utf8)  {
                print(string)
            }
            completion(nil)
        }
    }.resume()
}

func setRating(url: URLComponents, apiKey: String, setRatingRequest: SetRatingRequest, completion: @escaping (Bool?) -> Void) {
    var url = url
    url.path = "/edit_ratings/set_rating"
    
    let srr = SetRatingRequest(hash: setRatingRequest.hash, ratingServiceKey: setRatingRequest.ratingServiceKey, rating: setRatingRequest.rating, hydrusApiKey: apiKey)
    
    let encoder = JSONEncoder()
    guard let jsonData = try? encoder.encode(srr) else {
        print("Could not encode FileIds to JSON")
        completion(nil)
        return
    }
    
    guard let finalUrl = url.url else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    var request = URLRequest(url: finalUrl)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("URLSession data task failed with error: \(error)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data returned from server")
            completion(nil)
            return
        }
        
        completion(true)
        
    }.resume()
}

func editTags(url: URLComponents, apiKey: String, editTagsRequest: EditTagsRequest, completion: @escaping (Bool?) -> Void) {
    var url = url
    url.path = "/add_tags/add_tags"
    
    let addTagsRequest = EditTagsRequest.init(fileIds: editTagsRequest.fileIds, serviceKeysToActionsToTags: editTagsRequest.serviceKeysToActionsToTags, hydrusApiKey: apiKey)
    
    let encoder = JSONEncoder()
    guard let jsonData = try? encoder.encode(addTagsRequest) else {
        print("Could not encode FileIds to JSON")
        completion(nil)
        return
    }
    
    guard let finalUrl = url.url else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    var request = URLRequest(url: finalUrl)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("URLSession data task failed with error: \(error)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data returned from server")
            completion(nil)
            return
        }
        
        completion(true)
    }.resume()
}
