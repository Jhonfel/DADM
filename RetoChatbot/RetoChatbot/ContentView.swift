import SwiftUI

// Modelo de mensaje
struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

// Modelos para la API (sin cambios)
struct ChatRequest: Codable {
    let stream: Bool
    let model: String
    let messages: [ChatMessage]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let delta: Delta
}

struct Delta: Codable {
    let content: String?
}

// ViewModel (lógica principal sin cambios)
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading = false
    private let apiKey = ""
    private let apiUrl = "https://api.sambanova.ai/v1/chat/completions"
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: currentInput, isUser: true)
        messages.append(userMessage)
        
        let messageToSend = currentInput
        currentInput = ""
        isLoading = true
        
        let chatMessages = [
            ChatMessage(role: "system", content:"""
Eres una asistente experta en cocina. Tu objetivo es hacer que cocinar sea accesible y agradable para todos los niveles de experiencia.
no respondas cosas que no estén relacionadas con especificamente preparar platos, de cocina.
"""),
            ChatMessage(role: "user", content: messageToSend)
        ]
        
        let request = ChatRequest(
            stream: true,
            model: "Meta-Llama-3.3-70B-Instruct",
            messages: chatMessages
        )
        
        Task {
            await sendToAPI(request: request)
        }
    }
    
    private func sendToAPI(request: ChatRequest) async {
        guard let url = URL(string: apiUrl) else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (stream, response) = try await URLSession.shared.bytes(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await handleError("Error en la respuesta del servidor")
                return
            }
            
            var responseText = ""
            
            for try await line in stream.lines {
                if line.hasPrefix("data: "),
                   let jsonData = line.dropFirst(6).data(using: .utf8) {
                    do {
                        let streamResponse = try JSONDecoder().decode(ChatResponse.self, from: jsonData)
                        if let content = streamResponse.choices.first?.delta.content {
                            responseText += content
                            await updateAssistantMessage(responseText)
                        }
                    } catch {
                        print("Error decodificando stream: \(error)")
                    }
                }
            }
        } catch {
            await handleError("Error en la comunicación: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    @MainActor
    private func updateAssistantMessage(_ content: String) {
        if let lastMessage = messages.last, !lastMessage.isUser {
            messages[messages.count - 1] = Message(content: content, isUser: false)
        } else {
            messages.append(Message(content: content, isUser: false))
        }
    }
    
    @MainActor
    private func handleError(_ message: String) {
        messages.append(Message(content: "Error: \(message)", isUser: false))
        isLoading = false
    }
}

// Componentes de UI
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(BubbleShape(isUser: true))
                    .textSelection(.enabled)
                
                // Avatar del usuario
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            } else {
                // Avatar del asistente
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(BubbleShape(isUser: false))
                    .textSelection(.enabled)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct BubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

struct InputField: View {
    @Binding var text: String
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Escribe un mensaje...", text: $text)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .textFieldStyle(.plain)
                .submitLabel(.send)
                .onSubmit(action)
            
            Button(action: action) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Namespace private var bottomID
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                    Text("Asistente de cocina")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(bottomID)
                        }
                    }
                }
                
                // Input field
                InputField(
                    text: $viewModel.currentInput,
                    action: viewModel.sendMessage,
                    isLoading: viewModel.isLoading
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
