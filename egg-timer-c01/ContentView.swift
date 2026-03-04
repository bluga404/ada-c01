import SwiftUI
import Combine
import AVFoundation

// MARK: - Models
enum EggType: String, CaseIterable {
    case ayam = "Telur Ayam", puyuh = "Telur Puyuh"
}

enum WaterCondition: String, CaseIterable {
    case mentah = "Air Mentah", mendidih = "Air Mendidih"
}

enum Doneness: String, CaseIterable {
    case setengahMatang = "Setengah Matang", matang = "Matang", matangSempurna = "Matang Sempurna"
}

// MARK: - ViewModel
class BoilerViewModel: ObservableObject {
    @Published var selectedEgg: EggType = .ayam
    @Published var selectedWater: WaterCondition = .mentah
    @Published var selectedDoneness: Doneness = .setengahMatang
    
    @Published var secondsRemaining: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var showOverlay: Bool = false
    
    // Properti untuk Audio
    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?
    
    var totalDurationMinutes: Int {
        var base: Int = 0
        switch selectedDoneness {
        case .setengahMatang: base = 1
        case .matang: base = 8
        case .matangSempurna: base = 11
        }
        let extra = (selectedWater == .mentah) ? 3 : 0
        var total = base + extra
        if selectedEgg == .puyuh { total -= 2 }
        return max(total, 1)
    }
    
    func startTimer() {
            showOverlay = true // Munculkan overlay
            isTimerRunning = true // Jalankan hitungan
            
            // Reset waktu jika sudah nol
            if secondsRemaining <= 0 {
                secondsRemaining = totalDurationMinutes * 60
            }
            
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    if self.secondsRemaining > 0 {
                        self.secondsRemaining -= 1
                    } else {
                        self.timerFinished()
                    }
                }
        }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.cancel()
        // Jangan ubah showOverlay di sini agar overlay tetap muncul
    }

    func resetToReady() {
        stopTimer()
        secondsRemaining = totalDurationMinutes * 60
        // Overlay tetap terbuka karena showOverlay tidak diubah ke false
    }
    
    // Fungsi baru untuk benar-benar menutup overlay (misal tombol "Keluar")
    func closeOverlay() {
        stopTimer()
        showOverlay = false
    }

    func timerFinished() {
        stopTimer()
        playAlarmSound() // Mulai bunyikan alarm
                
        // Getaran haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // --- LOGIKA SUARA ---
        
    private func playAlarmSound() {
        // Ganti "alarm_sound" dengan nama file mp3/wav di Assets kamu
        guard let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // -1 artinya loop selamanya sampai di-stop
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Gagal memutar suara: \(error.localizedDescription)")
        }
    }

    private func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func formatTime() -> String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var vm = BoilerViewModel()
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        SelectionSection(title: "Jenis Telur") {
                            HStack {
                                SelectionButton(title: "Telur Ayam", isSelected: vm.selectedEgg == .ayam) { vm.selectedEgg = .ayam }
                                SelectionButton(title: "Telur Puyuh", isSelected: vm.selectedEgg == .puyuh) { vm.selectedEgg = .puyuh }
                            }
                        }
                        
                        SelectionSection(title: "Kondisi **Awal Air**") {
                            HStack {
                                SelectionButton(title: "Air Mentah", isSelected: vm.selectedWater == .mentah) { vm.selectedWater = .mentah }
                                SelectionButton(title: "Air Mendidih", isSelected: vm.selectedWater == .mendidih) { vm.selectedWater = .mendidih }
                            }
                        }
                        
                        SelectionSection(title: "Tingkat **Kematangan**") {
                            HStack(spacing: 12) {
                                DonenessCard(title: "Setengah Matang", icon: "egg.halved", isSelected: vm.selectedDoneness == .setengahMatang) { vm.selectedDoneness = .setengahMatang }
                                DonenessCard(title: "Matang", icon: "egg.fill", isSelected: vm.selectedDoneness == .matang) { vm.selectedDoneness = .matang }
                                DonenessCard(title: "Matang Sempurna", icon: "egg.fill", isSelected: vm.selectedDoneness == .matangSempurna) { vm.selectedDoneness = .matangSempurna }
                            }
                        }
                    }
                    .padding()
                }
                
                BottomTimerBar(minutes: vm.totalDurationMinutes) {
                    // Memicu overlay muncul DAN timer mulai
                    vm.startTimer()
                }
            }
            // Ubah isTimerRunning menjadi showOverlay agar interaksi di belakang
            // terkunci selama overlay masih terbuka (meskipun timer berhenti/reset)
            .disabled(vm.showOverlay)
            .blur(radius: vm.showOverlay ? 10 : 0)
            
            // Tampilan Timer menggunakan state showOverlay
            if vm.showOverlay {
                TimerOverlayView(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
            }
        }
        // Pastikan animasi mengikuti perubahan showOverlay
        .animation(.spring(), value: vm.showOverlay)
    }
}

// MARK: - Components
struct TimerOverlayView: View {
    @ObservedObject var vm: BoilerViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Memasak Telur...")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: CGFloat(vm.secondsRemaining) / CGFloat(vm.totalDurationMinutes * 60))
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: vm.secondsRemaining)
                    
                    Text(vm.formatTime())
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(width: 280, height: 280)
                
                HStack(spacing: 40) {
                    if vm.isTimerRunning {
                        // Tombol Reset: Berhenti dan balik ke waktu awal, tapi tetap di overlay
                        ControlButton(title: "Reset", icon: "arrow.clockwise", color: .white) {
                            vm.resetToReady()
                        }
                        
                        // Tombol Pause/Stop: Berhenti di detik saat ini, tetap di overlay
                        ControlButton(title: "Pause", icon: "pause.fill", color: .orange) {
                            vm.stopTimer()
                        }
                    } else {
                        // Tombol Start: Lanjut masak
                        ControlButton(title: "Start", icon: "play.fill", color: .yellow) {
                            vm.startTimer()
                        }
                        
                        // Tombol Keluar: Baru benar-benar menutup overlay
                        ControlButton(title: "Close", icon: "xmark.circle.fill", color: .red) {
                            vm.closeOverlay()
                        }
                    }
                }
            }
            .padding(40)
            .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(40))
            .padding()
        }
    }
}

struct ControlButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title.bold())
                Text(title).font(.caption).bold()
            }
            .foregroundColor(color)
        }
    }
}

// Helper untuk background blur transparan
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Komponen sisa (HeaderView, SelectionButton, SelectionSection, DonenessCard, BottomTimerBar) disatukan di sini...
// (Gunakan versi yang memiliki closure action pada BottomTimerBar)

struct SelectionSection<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(try! AttributedString(markdown: title)).font(.headline).foregroundColor(.gray)
            content
        }
    }
}

struct DonenessCard: View {
    let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).resizable().aspectRatio(contentMode: .fit).frame(height: 40)
                    .foregroundColor(isSelected ? .orange : .yellow)
                Text(title).font(.caption2).bold().multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(Color.white).cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: 2))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
        }
    }
}

struct SelectionButton: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline).frame(maxWidth: .infinity).padding()
                .background(Color.white).foregroundColor(isSelected ? .orange : .gray)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2))
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            Color.yellow
                .ignoresSafeArea(edges: .top)
                .frame(height: 0)
            
            ZStack(alignment: .bottomLeading) {
                Color.yellow
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BoiliT!")
                            .font(.system(size: 48, weight: .bold))
                        Text("Telurmu, Aturanmu")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    // Gambar Telur
                    Image("Telur")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                        // TIPS: Gunakan offset negatif jika ingin telur
                        // terlihat sedikit keluar dari layar (seperti di gambar contoh)
                        .offset(x: 40, y: 20)
                }
                .padding(.leading, 20) // Padding kiri tetap agar teks tidak nempel
                .padding(.bottom, 25)
            }
            // Tambahkan ini agar telur yang di-offset tidak menutupi konten di bawahnya
            .clipped()
            .frame(height: 180)
        }
    }
}

struct BottomTimerBar: View {
    let minutes: Int
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Estimated boiled time")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Perbaikan di sini: Hapus tanda petik tunggal (') sebelum tanda +
                Text("\(minutes):00").font(.title).bold() +
                Text(" Min").font(.subheadline)
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "play.fill")
                    .font(.title)
                    .padding()
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .foregroundColor(.white)
            }
        }
        .padding(30)
        .background(Color.white)
        // Opsional: Tambahkan shadow agar terlihat lebih "floating" di atas ScrollView
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
