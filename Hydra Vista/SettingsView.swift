import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("defaultSearch") private var defaultSearch = "rating:safe"
    @AppStorage("defaultSortType") private var defaultSortType = FileSortType.FileSize
    @AppStorage("defaultSortAsc") private var defaultSortAsc = false
    
    var body: some View {
        Form {
            TextField("Default tag", text: $defaultSearch)
            Picker("Default sort type", selection: $defaultSortType) {
                ForEach(FileSortType.allCases) { sortType in
                    Text(sortType.label)
                }
            }
            .pickerStyle(MenuPickerStyle())
            Toggle(isOn: $defaultSortAsc, label: {
                Text("Sort ascending by default?")
            })
        }
    }
}

struct RemoteSetingsView: View {
    @AppStorage("defaultSearch") private var defaultSearch = "rating:safe"
    @AppStorage("remoteHostname") private var remoteHostname = "127.0.0.1"
    @AppStorage("remotePort") private var remotePort = "45869"
    @AppStorage("remoteUseHttps") private var remoteUseHttps = false
    @AppStorage("remoteApiKey") private var remoteApiKey = ""
    
    var body: some View {
        Form {
            TextField("API Key", text: $remoteApiKey)
            TextField("Remote Hostname", text: $remoteHostname)
            TextField("Remote Port", text: $remotePort)
            Toggle("Use HTTPS?", isOn: $remoteUseHttps)
        }
    }
}

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, remote
    }
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            RemoteSetingsView()
                .tabItem {
                    Label("Remote", systemImage: "network")
                }
                .tag(Tabs.remote)
        }
        .padding(20)
    }
}
