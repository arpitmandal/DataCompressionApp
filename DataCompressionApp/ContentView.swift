import SwiftUI
import Compression
import AVFoundation

struct ContentView: View {
    @State private var selectedFile: URL?
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            
            // File Selection Section
            HStack {
                Button(action: {
                    selectFile()
                }) {
                    Text("Select File")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Remove File Button (visible only when a file is selected)
                if selectedFile != nil {
                    Button(action: {
                        removeFile()
                    }) {
                        Text("Remove File")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Display Selected File
            if let selectedFile = selectedFile {
                Text("Selected File: \(selectedFile.lastPathComponent)")
                    .font(.subheadline)
            }
            
            // Loader / Progress Bar
            if isProcessing {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
            }
            
            // Compress Button
            Button(action: {
                startCompression()
            }) {
                Text("Compress File")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(selectedFile == nil || isProcessing) // Disable if no file selected or processing
            .opacity(selectedFile == nil || isProcessing ? 0.5 : 1.0) // Optional: Dim button when disabled
            
            // Message Ribbon
            if showError || !successMessage.isEmpty {
                Text(showError ? errorMessage : successMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(showError ? Color.red : Color.green)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Contact Support Section
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
        .padding()
    }
    
    // MARK: - Helper Functions
    
    // Function to handle file selection
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "mp4", "mp3", "mov", "pdf"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            self.selectedFile = panel.url
        }
    }
    
    // Function to remove the selected file
    private func removeFile() {
        selectedFile = nil
        showError = false
        isProcessing = false
        progress = 0.0
        errorMessage = ""
        successMessage = ""
    }
    
    // Function to start compression
    private func startCompression() {
        guard selectedFile != nil else {
            showErrorMessage("No file selected.")
            return
        }
        
        isProcessing = true
        showError = false
        progress = 0.0
        successMessage = ""
        
        // Call compressFile to handle compression based on file type
        compressFile()
    }
    
    private func compressFile() {
        guard let selectedFile = selectedFile else { return }
        
        // Check file type and apply compression
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
            return
        }
    }
    
    // Function to show an error message
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
    
    private func promptSaveFile(originalFile: URL) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Compressed File"
        savePanel.nameFieldStringValue = "Compressed_" + originalFile.lastPathComponent
        savePanel.allowedFileTypes = [originalFile.pathExtension]
        
        if savePanel.runModal() == .OK {
            if let destinationURL = savePanel.url {
                // Save the compressed file to the selected location
                do {
                    try FileManager.default.copyItem(at: originalFile, to: destinationURL)
                    showSuccessMessage("File saved successfully!")
                } catch {
                    showErrorMessage("Failed to save file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveCompressedData(_ data: Data?, originalFile: URL) {
        guard let data = data else {
            showErrorMessage("Compression failed.")
            return
        }
        
        let compressedFileURL = originalFile.deletingPathExtension().appendingPathExtension("compressed.\(originalFile.pathExtension)")

        do {
            try data.write(to: compressedFileURL)
            self.showSuccessMessage("\(originalFile.pathExtension.uppercased()) file compressed successfully!")
            self.promptSaveFile(originalFile: compressedFileURL)
        } catch {
            showErrorMessage("Failed to save compressed file: \(error.localizedDescription)")
        }
    }
    
    private func compressImageFile(_ file: URL) {
        guard let image = NSImage(contentsOf: file),
              let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            showErrorMessage("Failed to load image.")
            return
        }

        // Adjust compression quality (e.g., 0.5 for 50% quality)
        let compressedData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.5])

        saveCompressedData(compressedData, originalFile: file)
    }

    private func compressVideoFile(_ file: URL) {
        let asset = AVAsset(url: file)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)

        let compressedFileURL = file.deletingPathExtension().appendingPathExtension("compressed.mov")
        exportSession?.outputURL = compressedFileURL
        exportSession?.outputFileType = .mov

        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed {
                    self.showSuccessMessage("Video file compressed successfully!")
                    self.promptSaveFile(originalFile: compressedFileURL)
                } else {
                    self.showErrorMessage("Video compression failed.")
                }
            }
        }
    }

    private func compressAudioFile(_ file: URL) {
        let compressedFileURL = file.deletingPathExtension().appendingPathExtension("compressed.m4a")
        
        let asset = AVAsset(url: file)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        exportSession?.outputURL = compressedFileURL
        exportSession?.outputFileType = .m4a
        exportSession?.audioTimePitchAlgorithm = .varispeed

        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed {
                    self.showSuccessMessage("Audio file compressed successfully!")
                    self.promptSaveFile(originalFile: compressedFileURL)
                } else {
                    self.showErrorMessage("Audio compression failed.")
                }
            }
        }
    }
    
    private func compressPDFFile(_ file: URL) {
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
