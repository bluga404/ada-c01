import SwiftUI
import UserNotifications

struct ContentView: View {
    
    @State private var selectedMinutes = 1
    @State private var selectedSeconds = 0
    
    @State private var timeRemaining: TimeInterval = 60
    @State private var timer: Timer?
    @State private var isRunning = false
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text(formatTime(timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            
            // Picker muncul hanya kalau timer belum jalan
            if !isRunning {
                HStack {
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120, height: 120)
                    
                    Picker("Seconds", selection: $selectedSeconds) {
                        ForEach(0..<60) { second in
                            Text("\(second) sec").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120, height: 120)
                }
            }
            
            HStack(spacing: 30) {
                
                Button(isRunning ? "Pause" : "Start") {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }
                .frame(width: 100, height: 50)
                .background(isRunning ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Reset") {
                    resetTimer()
                }
                .frame(width: 100, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    func startTimer() {
        if timeRemaining <= 0 {
            timeRemaining = TimeInterval(selectedMinutes * 60 + selectedSeconds)
        }
        
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                pauseTimer()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = TimeInterval(selectedMinutes * 60 + selectedSeconds)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
