import SwiftUI

struct TermListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = TermViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSidebarVisible = false
    @State private var isAddTermViewVisible = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    
    // Sınıf seviyelerini belirli sırayla gösterebilmek için
    private let classLevelOrder: [String] = ["pre", "1", "2", "3", "4"]
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .leading) {
                mainContent
                
                if isAddTermViewVisible {
                    AddTermPanel(
                        isVisible: $isAddTermViewVisible,
                        termViewModel: viewModel
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { sidebarOverlay }
            .onAppear { viewModel.fetchTerms() }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            contentView
            addButton
        }
    }
    
    /// İçerik: Yükleniyor, hata, boş liste veya dönemler gruplaması
    private var contentView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.errorMessage.isEmpty {
                errorView
            } else if viewModel.terms.isEmpty {
                emptyStateView
            } else {
                termListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                menuButton
            }
            
            ToolbarItem(placement: .principal) {
                titleView
            }
        }
    }
    
    private var menuButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: isSidebarVisible ? "xmark" : "line.horizontal.3")
                .imageScale(.large)
                .foregroundColor(.primary)
                .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
        }
    }
    
    private var titleView: some View {
        Group {
            if !isSidebarVisible {
                Text(LocalizedStringKey("your_terms"))
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Gruplanmış Liste
    private var termListView: some View {
        // 1) Dönemleri classLevel'a göre grupla
        let groupedTerms = Dictionary(grouping: viewModel.terms, by: { $0.classLevel })
        
        return List {
            // 2) Belirlediğimiz sıraya göre her classLevel için Section aç
            ForEach(classLevelOrder, id: \.self) { level in
                let termsForLevel = groupedTerms[level] ?? []
                
                // 3) Bu level’da dönem varsa Section oluştur
                if !termsForLevel.isEmpty {
                    Section(header: Text(localizedClassLevelName(for: level))) {
                        // 4) “Dönem X” satırları
                        ForEach(termsForLevel) { term in
                            NavigationLink(destination: CourseListView(term: term)) {
                                Text(String(format: NSLocalizedString("term_format", comment: ""), term.termNumber))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 8)
                            }
                        }
                        // 5) Silme işlemi (Section içinde)
                        .onDelete { offsets in
                            for offset in offsets {
                                let term = termsForLevel[offset]
                                viewModel.deleteTerm(termId: term.id) { _ in }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Yardımcı: class_level -> Localizable
    private func localizedClassLevelName(for level: String) -> LocalizedStringKey {
        switch level {
        case "pre":
            return "class_level_pre"
        case "1":
            return "class_level_1"
        case "2":
            return "class_level_2"
        case "3":
            return "class_level_3"
        case "4":
            return "class_level_4"
        default:
            return LocalizedStringKey(level)
        }
    }
    
    // MARK: - Supporting Views
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text(viewModel.errorMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(LocalizedStringKey("no_terms"))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addButton: some View {
        Button(action: showAddTermPanel) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Sidebar Overlay
    private var sidebarOverlay: some View {
        Group {
            if isSidebarVisible {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeSidebar)
                    
                    HStack(spacing: 0) {
                        SidebarView(isVisible: $isSidebarVisible)
                            .environmentObject(authViewModel)
                            .frame(width: UIScreen.main.bounds.width * 0.75)
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
                .zIndex(2)
            }
        }
    }
    
    // MARK: - Actions
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
            isSidebarVisible.toggle()
        }
    }
    
    private func closeSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
            isSidebarVisible = false
        }
    }
    
    private func showAddTermPanel() {
        withAnimation(.spring()) {
            isAddTermViewVisible = true
        }
    }

}
