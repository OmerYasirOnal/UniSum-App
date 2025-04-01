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
                // Gradient arka plan
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                mainContent
                
                if isAddTermViewVisible {
                    AddTermPanel(
                        isVisible: $isAddTermViewVisible,
                        termViewModel: viewModel
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { sidebarOverlay }
            .onAppear { viewModel.fetchTerms() }
            .navigationDestination(for: Term.self) { term in
                CourseListView(term: term)
            }
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
                loadingView
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
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }
    
    private var titleView: some View {
        Group {
            if !isSidebarVisible {
                Text(LocalizedStringKey("your_terms"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
    
    // MARK: - Gruplanmış Liste
    private var termListView: some View {
        // 1) Dönemleri classLevel'a göre grupla
        let groupedTerms = Dictionary(grouping: viewModel.terms, by: { $0.classLevel })
        
        return ScrollView {
            VStack(spacing: 20) {
                // 2) Belirlediğimiz sıraya göre her classLevel için Section aç
                ForEach(classLevelOrder, id: \.self) { level in
                    let termsForLevel = groupedTerms[level] ?? []
                    
                    // 3) Bu level'da dönem varsa Section oluştur
                    if !termsForLevel.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Bölüm başlığı
                            Text(localizedClassLevelName(for: level))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // 4) "Dönem X" kartları
                            ForEach(termsForLevel) { term in
                                TermCardView(term: term, navigationPath: $navigationPath)
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            viewModel.deleteTerm(termId: term.id) { _ in }
                                        }) {
                                            Label(LocalizedStringKey("delete"), systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        
                        if level != classLevelOrder.last {
                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .refreshable {
            viewModel.fetchTerms()
        }
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
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text(LocalizedStringKey("loading_terms"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .symbolEffect(.pulse)
            
            Text(viewModel.errorMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.fetchTerms()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(LocalizedStringKey("try_again"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .symbolEffect(.pulse)
            
            Text(LocalizedStringKey("no_terms"))
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(LocalizedStringKey("add_term_instruction"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Image(systemName: "arrow.down")
                .font(.title)
                .foregroundColor(.accentColor)
                .padding()
                .symbolEffect(.bounce)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addButton: some View {
        Button(action: showAddTermPanel) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 65, height: 65)
                    .shadow(color: .accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Image(systemName: "plus")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
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
                            .shadow(color: .black.opacity(0.3), radius: 5)
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

// MARK: - Term Card Bileşeni
struct TermCardView: View {
    let term: Term
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        Button(action: {
            // Debug için termId yazdırılıyor
            print("Navigating to term: \(term.description())")
            navigationPath.append(term)
        }) {
            HStack(spacing: 15) {
                // İkon
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.accentColor)
                    )
                
                // Dönem bilgisi
                VStack(alignment: .leading, spacing: 4) {
                    // Güvenli erişim için String dönüşümü yapıyoruz
                    let termNumberText = String(format: NSLocalizedString("term_format", comment: ""), String(term.termNumber))
                    Text(termNumberText)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Toplam kredi bilgisi
                    Text(String(format: NSLocalizedString("term_credits_format", comment: ""), term.totalCredits))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Sağ ok
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.trailing, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
