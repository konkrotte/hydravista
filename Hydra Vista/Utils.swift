import Foundation
import SwiftUI

struct CountedSet<Element: Hashable> {
    private(set) var elements: [Element: Int] = [:]
    mutating func insert(_ member: Element) {
        elements[member, default: 0] += 1
    }
    mutating func remove(_ member: Element) -> Element? {
        guard var count = elements[member], count > 0 else { return nil }
        count -= 1
        elements[member] = count == 0 ? nil : count
        return member
    }
    subscript(_ member: Element) -> Int {
        elements[member] ?? 0
    }
}

extension CountedSet: ExpressibleByArrayLiteral, CustomStringConvertible {

    typealias ArrayLiteralElement = Element
    init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.elements = sequence.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }
    init(arrayLiteral elements: Element...)  { self.init(elements) }
    var description: String { .init(describing: elements) }
}

extension Array {
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func downloadFile(from url: URL, moveToDownloads: Bool, customFileName: String? = nil, completion: @escaping (URL?, Error?) -> Void) {
    let task = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
        guard let tempURL = tempURL, error == nil else {
            completion(nil, error)
            return
        }
        
        do {
            let documentsURL = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            let fileName = customFileName ?? url.lastPathComponent
            let destinationURL = documentsURL.appendingPathComponent(fileName)
            
            if moveToDownloads {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL, nil)
            } else {
                let tempDirectory = FileManager.default.temporaryDirectory
                let destinationURL = tempDirectory.appendingPathComponent(fileName)
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL, nil)
            }
        } catch {
            completion(nil, error)
        }
    }
    
    task.resume()
}
