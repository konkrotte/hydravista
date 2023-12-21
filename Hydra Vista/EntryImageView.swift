import SwiftUI
import NukeUI
import SwiftUIX

protocol ScrollViewDelegateProtocol {
    func scrollWheel(with event: NSEvent);
}

class ImageScrollView: NSView {
    var delegate: ScrollViewDelegateProtocol!
    override var acceptsFirstResponder: Bool { true }
    override func scrollWheel(with event: NSEvent) {
        delegate.scrollWheel(with: event)
    }
}

struct RepresentableScrollView: NSViewRepresentable, ScrollViewDelegateProtocol {
    typealias NSViewType = ImageScrollView
    
    private var scrollAction: ((NSEvent) -> Void)?
    
    func makeNSView(context: Context) -> ImageScrollView {
        let view = ImageScrollView()
        view.delegate = self;
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    
    func scrollWheel(with event: NSEvent) {
        if let scrollAction = scrollAction {
            scrollAction(event)
        }
    }
    
    func onScroll(_ action: @escaping (NSEvent) -> Void) -> Self {
        var newSelf = self
        newSelf.scrollAction = action
        return newSelf
    }
}

extension CGSize: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(CGSize.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension CGFloat: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(CGFloat.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

struct EntryImageView: View {
    @State var url: URL
    @State var blurHash: String
    @State var size: CGSize
    /*@SceneStorage("EntryImageView.Offset")*/ @State private var offset: CGSize = CGSize(width: 0.0, height: 0.0)
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var scrollView: some View {
        RepresentableScrollView()
            .onScroll { event in
                var newOffset = CGSize(
                    width: offset.width + event.deltaX,
                    height: offset.height + event.deltaY
                )
                
                offset = newOffset
            }
    }
    
    var body: some View {
        GeometryReader { proxy in
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(offset)
                        .scaleEffect(scale)
                        .overlay(scrollView)
                        .draggable(image)
                        .gesture(MagnificationGesture()
                            .onChanged { val in
                                let delta = val / lastScale
                                lastScale = val
                                var newScale = scale * delta
                                if newScale < 1.0 {
                                    newScale = 1.0
                                }
                                scale = newScale
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                        )
                        .onReceive(NotificationCenter.default.publisher(for: .resetImageNotification), perform: { _ in
                            scale = 1.0
                            offset.width = 0
                            offset.height = 0
                        })
                        .onReceive(NotificationCenter.default.publisher(for: .zoomImageNotification), perform: { notification in
                            if let val = notification.userInfo?["factor"] as? CGFloat {
                                if scale + val > 1.0 {
                                    scale += val
                                } else {
                                    scale = 1.0
                                }
                            }
                        })

                } else if state.error != nil {
                    Text("Error loading image")
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    Image(blurHash: blurHash/*, size: size*/)!
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .aspectRatio(contentMode: .fit)
                }
            }
            .transition(.opacity)
        }
    }
}
