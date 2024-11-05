import SwiftUI
import Compression
import AVFoundation
import PDFKit

struct ContentView: View {
    @State private var selectedFile: URL?
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            HStack(alignment: .center) {
                Button(action: { selectFile() }) {
                    Text("Select File")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if selectedFile != nil {
                    Button(action: { removeFile() }) {
                        Text("Remove File")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            if let selectedFile = selectedFile {
                Text("Selected File: \(selectedFile.lastPathComponent)")
                    .font(.subheadline)
            }
            
            if isProcessing {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
            }
            
            Button(action: { startCompression() }) {
                Text("Compress File")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(selectedFile == nil || isProcessing)
            .opacity(selectedFile == nil || isProcessing ? 0.5 : 1.0)
            
            if showError || !successMessage.isEmpty {
                Text(showError ? errorMessage : successMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(showError ? Color.red : Color.green)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            VStack {
                Text("Contact Support")
                    .font(.headline)
                Text("Arpit Mandal")
                Text("Email: arpitmandal.work@gmail.com")
                Text("Phone: +1-226-899-0029")
            }
            .font(.footnote)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.vertical, 25.0)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "mp4", "mp3", "mov", "pdf"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            self.selectedFile = panel.url
        }
    }
    
    private func removeFile() {
        selectedFile = nil
        showError = false
        isProcessing = false
        progress = 0.0
        errorMessage = ""
        successMessage = ""
    }
    
    private func startCompression() {
        guard selectedFile != nil else {
            showErrorMessage("No file selected.")
            return
        }
        
        isProcessing = true
        showError = false
        progress = 0.0
        successMessage = ""
        
        compressFile()
    }
    
    private func compressFile() {
        guard let selectedFile = selectedFile else { return }
        let fileType = selectedFile.pathExtension.lowercased()
        switch fileType {
        case "jpg", "jpeg", "png":
            compressImageFile(selectedFile)
        case "mp4", "mov":
            compressVideoFile(selectedFile)
        case "mp3":
            compressAudioFile(selectedFile)
        case "pdf":
            compressPDFFile(selectedFile)
        default:
            showErrorMessage("Unsupported file type.")
        }
    }
    
    private func compressImageFile(_ file: URL) {
        guard let image = NSImage(contentsOf: file),
              let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            showErrorMessage("Failed to load image.")
            return
        }

        let compressedData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.5])
        promptSaveFile(data: compressedData)
    }

    private func compressVideoFile(_ file: URL) {
        let asset = AVAsset(url: file)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.outputFileType = .mov
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed, let outputURL = exportSession?.outputURL {
                    if let compressedData = try? Data(contentsOf: outputURL) {
                        self.promptSaveFile(data: compressedData)
                    } else {
                        self.showErrorMessage("Failed to load compressed video.")
                    }
                } else {
                    self.showErrorMessage("Video compression failed.")
                }
            }
        }
    }

    private func compressAudioFile(_ file: URL) {
        let asset = AVAsset(url: file)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exportSession?.outputFileType = .m4a
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed, let outputURL = exportSession?.outputURL {
                    if let compressedData = try? Data(contentsOf: outputURL) {
                        self.promptSaveFile(data: compressedData)
                    } else {
                        self.showErrorMessage("Failed to load compressed audio.")
                    }
                } else {
                    self.showErrorMessage("Audio compression failed.")
                }
            }
        }
    }
    
    private func compressPDFFile(_ file: URL) {
        guard let pdfData = try? Data(contentsOf: file),
              let pdfDocument = PDFDocument(data: pdfData) else {
            showErrorMessage("Failed to load PDF.")
            return
        }
        
        let compressedData = pdfDocument.dataRepresentation()
        promptSaveFile(data: compressedData)
    }
    
    private func promptSaveFile(data: Data?) {
        guard let data = data else {
            showErrorMessage("Compression failed.")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Compressed File"
        savePanel.allowedFileTypes = ["jpeg", "jpg", "png", "mov", "m4a", "pdf"]
        
        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                try data.write(to: destinationURL)
                showSuccessMessage("File saved successfully!")
            } catch {
                showErrorMessage("Failed to save file: \(error.localizedDescription)")
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
            errorMessage = ""
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showError = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            successMessage = ""
        }
    }
}
