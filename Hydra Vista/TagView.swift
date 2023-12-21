import SwiftUI

struct TagView: View {
    @State var tag: String
    var exclude: (String) -> Void
    var add: (String) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Text(tag)
            Spacer()
            Button(action: {
                exclude(tag)
            }) {
                Image(systemName: "minus.circle") .foregroundColor(.accentColor)
            }.help("Exclude the tag from the search")
            Button(action: {
                add(tag)
            }) {
                Image(systemName: "plus.circle") .foregroundColor(.accentColor)
            }.help("Add the tag to the search")
        }
    }
}

struct TagSectionView: View {
    @ObservedObject var entryVM: EntriesViewModel
    @State var expanded: Bool
    @State var tags: [String]
    @State var service: String

    var body: some View {
        DisclosureGroup(isExpanded: $expanded, content: {
            ForEach(tags, id: \.self) { tag in
                TagView(tag: tag, exclude: { tag in
                    entryVM.search.update(with: "-\(tag)")
                }, add: { tag in
                    entryVM.search.update(with: tag)
                })
            }
        }, label: {
            Text(service).font(.headline)
                .onTapGesture {
                    expanded.toggle()
                }
        })
    }
}

