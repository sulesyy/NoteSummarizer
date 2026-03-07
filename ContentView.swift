import SwiftUI
import AVFoundation
import PDFKit
import UniformTypeIdentifiers
import NaturalLanguage
import Vision
import VisionKit

enum AppTheme: String, CaseIterable {
    case system = "Sistem"
    case light = "Açık"
    case dark = "Koyu"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SavedSummary: Identifiable, Codable {
    var id = UUID()
    let originalText: String
    let summary: String
    let date: Date
    var type: String?
}

struct StreamResponse: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}

class HapticManager {
    static let shared = HapticManager()
    
 
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
   
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String) {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let probabilities = recognizer.languageHypotheses(withMaximum: 2)
        
        if probabilities.keys.contains(.turkish) {
            utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        synthesizer.speak(utterance)
    }
    
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = true } }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = false } }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = false } }
}

struct DocumentCameraView: UIViewControllerRepresentable {
    var onRecognizedText: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentCameraView
        
        init(_ parent: DocumentCameraView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var extractedText = ""
            let dispatchGroup = DispatchGroup()
            
            for pageIndex in 0..<scan.pageCount {
                dispatchGroup.enter()
                let image = scan.imageOfPage(at: pageIndex)
                guard let cgImage = image.cgImage else {
                    dispatchGroup.leave()
                    continue
                }
                
                let request = VNRecognizeTextRequest { request, error in
                    guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                        dispatchGroup.leave()
                        return
                    }
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    extractedText += text + "\n\n"
                    dispatchGroup.leave()
                }
                request.recognitionLanguages = ["tr-TR", "en-US"]
                request.recognitionLevel = .accurate
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
            
            dispatchGroup.notify(queue: .main) {
                HapticManager.shared.playNotification(type: .success) // Taramada başarı titreşimi
                self.parent.onRecognizedText(extractedText)
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            HapticManager.shared.playNotification(type: .error)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct ContentView: View {
    @AppStorage("appTheme") private var currentTheme: AppTheme = .system
    
    @State private var inputText = ""
    @State private var summaryText = ""
    @State private var isLoading = false
    @State private var savedSummaries: [SavedSummary] = []
    @State private var summaryType = "Short"
    
    @State private var showHistory = false
    @State private var showFileImporter = false
    @State private var showCameraScanner = false
    
    @StateObject private var speechManager = SpeechManager()
    @State private var summaryTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 15) {
                
               
                HStack {
                    Text("Notes AI").font(.largeTitle).bold()
                    Spacer()
                    Menu {
                        Picker("Tema Seç", selection: $currentTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    } label: {
                        Image(systemName: currentTheme == .dark ? "moon.circle.fill" : "sun.max.circle")
                            .font(.title2).foregroundColor(.primary)
                    }
                    .padding(.trailing, 5)
                    .onTapGesture {
                        HapticManager.shared.playImpact(style: .light)
                    }
                    
                    Button(action: {
                        HapticManager.shared.playImpact(style: .medium)
                        showHistory.toggle()
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2).foregroundColor(.primary)
                    }
                }
                
            
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        .onChange(of: inputText) { newValue in
                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                summaryText = ""
                                speechManager.stop()
                                summaryTask?.cancel()
                            }
                        }
                    
                    if !inputText.isEmpty {
                        Button(action: {
                            HapticManager.shared.playImpact(style: .rigid) // Çöp tenekesine basınca sert titreşim
                            inputText = ""
                            summaryText = ""
                            speechManager.stop()
                            summaryTask?.cancel()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                }
                
                
                Picker("Summary Type", selection: $summaryType) {
                    Text("Short").tag("Short")
                    Text("Detailed").tag("Detailed")
                    Text("Bullet Points").tag("Bullets")
                }
                .pickerStyle(.segmented)
                .onChange(of: summaryType) { _ in
                    HapticManager.shared.playImpact(style: .soft) // Kategori değiştirince yumuşak titreşim
                    summaryText = ""
                    speechManager.stop()
                    summaryTask?.cancel()
                }
                
              
                HStack {
                    Text("Characters: \(inputText.count)").font(.caption).foregroundColor(.gray)
                    Spacer()
                    
                  
                    Button(action: {
                        HapticManager.shared.playImpact(style: .medium)
                        showCameraScanner = true
                    }) {
                        Label("Tara", systemImage: "camera.viewfinder")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    
                
                    Button(action: {
                        HapticManager.shared.playImpact(style: .medium)
                        showFileImporter = true
                    }) {
                        Label("PDF", systemImage: "doc.text.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
              
                Button(action: startSummarizing) {
                    HStack {
                        Spacer()
                        Text(isLoading ? "Thinking..." : "Summarize")
                            .foregroundColor(.white).bold().padding()
                        Spacer()
                    }
                    .background(Color.green).cornerRadius(10)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                
         
                if !summaryText.isEmpty || isLoading {
                    Text("Summary").font(.headline).padding(.top)
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading) {
                                Text(summaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .onChange(of: summaryText) { _ in
                                withAnimation(.easeOut(duration: 0.1)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    
                    if !isLoading && !summaryText.isEmpty {
                        HStack {
                            Button("Copy") {
                                UIPasteboard.general.string = summaryText
                                HapticManager.shared.playNotification(type: .success) // Kopyalama başarılı
                            }
                            Spacer()
                            Button(speechManager.isSpeaking ? "Stop" : "Speak") {
                                HapticManager.shared.playImpact(style: .medium)
                                speechManager.speak(text: summaryText)
                            }
                            .foregroundColor(speechManager.isSpeaking ? .red : .blue)
                            Spacer()
                            Button("Share") {
                                HapticManager.shared.playImpact(style: .medium)
                                shareSummary()
                            }
                        }
                        .padding(.top)
                    }
                }
                
                Spacer()
            }
            .padding()
            .fullScreenCover(isPresented: $showCameraScanner) {
                DocumentCameraView { text in
                    if inputText.isEmpty {
                        inputText = text
                    } else {
                        inputText += "\n\n" + text
                    }
                    showCameraScanner = false
                }
                .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(summaries: $savedSummaries) { selected in
                    inputText = selected.originalText
                    summaryText = selected.summary
                    summaryType = selected.type ?? "Short"
                    showHistory = false
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .onAppear(perform: loadHistory)
        }
        .preferredColorScheme(currentTheme.colorScheme)
    }
    

    func handleFileSelection(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            if selectedFile.startAccessingSecurityScopedResource() {
                isLoading = true
                DispatchQueue.global(qos: .userInitiated).async {
                    var extractedText = ""
                    if let pdfDocument = PDFDocument(url: selectedFile) {
                        for i in 0..<pdfDocument.pageCount {
                            if let page = pdfDocument.page(at: i), let pageText = page.string {
                                extractedText += pageText + "\n"
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        selectedFile.stopAccessingSecurityScopedResource()
                        self.inputText = extractedText
                        self.isLoading = false
                        if extractedText.isEmpty {
                            HapticManager.shared.playNotification(type: .error)
                            self.summaryText = "PDF okunamadı veya içinde metin yok."
                        } else {
                            HapticManager.shared.playNotification(type: .success)
                        }
                    }
                }
            }
        } catch {
            HapticManager.shared.playNotification(type: .error)
            self.summaryText = "Dosya seçilirken hata oluştu: \(error.localizedDescription)"
        }
    }
    
  
    func startSummarizing() {
        HapticManager.shared.playImpact(style: .heavy) // Özetle butonuna basınca güçlü titreşim
        
        if let existing = savedSummaries.first(where: { $0.originalText == inputText && $0.type == summaryType }) {
            self.summaryText = existing.summary
            HapticManager.shared.playNotification(type: .success) // Geçmişten gelirse başarı titreşimi
            return
        }
        
    
        let apiKey = "BURAYA_API_ANAHTARINI_YAZ"
        if apiKey.isEmpty {
            self.summaryText = "Lütfen kodun içindeki apiKey kısmına anahtarınızı girin."
            HapticManager.shared.playNotification(type: .error)
            return
        }
        
        summaryTask?.cancel()
        speechManager.stop()
        isLoading = true
        summaryText = ""
        
        summaryTask = Task {
            defer {
                Task { @MainActor in
                    self.isLoading = false
                }
            }
            
            let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let json: [String: Any] = [
                "model": "llama-3.1-8b-instant",
                "stream": true,
                "messages": [
                    ["role": "system", "content": "You are a professional summarizer."],
                    ["role": "user", "content": "Please summarize the following text in the SAME language as the input, in \(summaryType.lowercased()) format:\n\n\(inputText)"]
                ]
            ]
            
            guard let body = try? JSONSerialization.data(withJSONObject: json) else { return }
            request.httpBody = body
            
            do {
                let (result, response) = try await URLSession.shared.bytes(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                
                if httpResponse.statusCode != 200 {
                    await MainActor.run {
                        HapticManager.shared.playNotification(type: .error) // Hata titreşimi
                        if httpResponse.statusCode == 429 {
                            self.summaryText = "Çok hızlı istek attınız. Lütfen birkaç saniye bekleyip tekrar deneyin."
                        } else {
                            self.summaryText = "API Hatası (Kod: \(httpResponse.statusCode)). Lütfen tekrar deneyin."
                        }
                    }
                    return
                }
                
                for try await line in result.lines {
                    if Task.isCancelled { break }
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.isEmpty { continue }
                    
                    if trimmedLine.hasPrefix("data: ") {
                        let dataString = trimmedLine.dropFirst(6)
                        if dataString == "[DONE]" { break }
                        
                        if let data = dataString.data(using: .utf8),
                           let decoded = try? JSONDecoder().decode(StreamResponse.self, from: data),
                           let content = decoded.choices.first?.delta.content {
                            await MainActor.run { self.summaryText += content }
                        }
                    }
                }
                
                if !Task.isCancelled && !self.summaryText.isEmpty {
                    await MainActor.run {
                        HapticManager.shared.playNotification(type: .success) // BİTİŞTE BAŞARI TİTREŞİMİ! 🌟
                        self.saveToHistory(original: self.inputText, summary: self.summaryText, type: self.summaryType)
                    }
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        HapticManager.shared.playNotification(type: .error)
                        self.summaryText = "Bağlantı veya sunucu hatası oluştu.\nLütfen tekrar deneyin."
                    }
                }
            }
        }
    }
    
   
    func saveToHistory(original: String, summary: String, type: String) {
        let newEntry = SavedSummary(originalText: original, summary: summary, date: Date(), type: type)
        savedSummaries.insert(newEntry, at: 0)
        if let encoded = try? JSONEncoder().encode(savedSummaries) {
            UserDefaults.standard.set(encoded, forKey: "SummaryHistory")
        }
    }
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "SummaryHistory"),
           let decoded = try? JSONDecoder().decode([SavedSummary].self, from: data) {
            savedSummaries = decoded
        }
    }
    
    func shareSummary() {
        let activityVC = UIActivityViewController(activityItems: [summaryText], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}


struct HistoryView: View {
    @Binding var summaries: [SavedSummary]
    var onSelect: (SavedSummary) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(summaries) { item in
                    Button {
                        HapticManager.shared.playImpact(style: .light)
                        onSelect(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(item.type ?? "Short")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(5)
                                Spacer()
                                Text(item.date, style: .date).font(.caption2).foregroundColor(.gray)
                            }
                            Text(item.summary).lineLimit(3).font(.subheadline)
                        }.padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }
                .onDelete { offsets in
                    HapticManager.shared.playImpact(style: .rigid) // Geçmişten silince titreşim
                    deleteItems(at: offsets)
                }
            }
            .navigationTitle("History")
            .toolbar { EditButton() }
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        summaries.remove(atOffsets: offsets)
        if let encoded = try? JSONEncoder().encode(summaries) {
            UserDefaults.standard.set(encoded, forKey: "SummaryHistory")
        }
    }
}

#Preview {
    ContentView()
}
