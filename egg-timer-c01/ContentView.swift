//
//  ContentView.swift
//  egg-timer-c01
//
//  Created by Academy on 03/03/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedOption: String? = nil
    @State private var selectedLevel: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                
                Text("Kematangan Air")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Kondisi Air
                VStack(alignment: .leading, spacing: 15) {
                    Text("Kondisi Air")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        OptionCard(
                            title: "Mentah",
                            icon: "drop.fill",
                            color: .blue,
                            isSelected: selectedOption == "Mentah"
                        ) {
                            selectedOption = "Mentah"
                        }
                        
                        OptionCard(
                            title: "Mendidih",
                            icon: "flame.fill",
                            color: .orange,
                            isSelected: selectedOption == "Mendidih"
                        ) {
                            selectedOption = "Mendidih"
                        }
                    }
                }
                
                // Tingkat Kematangan
                VStack(alignment: .leading, spacing: 15) {
                    Text("Tingkat Kematangan")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        LevelCard(
                            title: "Setengah",
                            color: .yellow,
                            isSelected: selectedLevel == "Setengah"
                        ) {
                            selectedLevel = "Setengah"
                        }
                        
                        LevelCard(
                            title: "Matang",
                            color: .orange,
                            isSelected: selectedLevel == "Matang"
                        ) {
                            selectedLevel = "Matang"
                        }
                        
                        LevelCard(
                            title: "Sempurna",
                            color: .red,
                            isSelected: selectedLevel == "Sempurna"
                        ) {
                            selectedLevel = "Sempurna"
                        }
                    }
                }
                
                Spacer()
                
                // Start Button
                NavigationLink(destination: TimerView(
                    selectedOption: selectedOption ?? "Mentah",
                    selectedLevel: selectedLevel ?? "Setengah"
                )) {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background((selectedOption != nil && selectedLevel != nil) ? Color.blue : Color.gray)
                        .cornerRadius(15)
                }
                .disabled(selectedOption == nil || selectedLevel == nil)
                
                Spacer()
            }
            .padding()
        }
    }
}


// MARK: - Timer Screen
struct TimerView: View {
    var selectedOption: String
    var selectedLevel: String
    
    @State private var countdownTimer: Int = 5
    @State private var timerRunning = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("\(countdownTimer)")
                .font(.system(size: 60, weight: .bold))
            
            HStack(spacing: 30) {
                Button(timerRunning ? "Pause" : "Start") {
                    timerRunning.toggle()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(15)
                
                Button("Reset") {
                    countdownTimer = initialTime()
                    timerRunning = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
            }
        }
        .onAppear {
            countdownTimer = initialTime()
        }
        .onReceive(timer) { _ in
            if countdownTimer > 0 && timerRunning {
                countdownTimer -= 1
            } else {
                timerRunning = false
            }
        }
    }
    
    // Set timer based on pilihan tingkat kematangan
    func initialTime() -> Int {
        switch selectedLevel {
        case "Setengah": return 5
        case "Matang": return 10
        case "Sempurna": return 15
        default: return 5
        }
    }
}


// MARK: - Reusable Components
struct OptionCard: View {
    var title: String
    var icon: String
    var color: Color
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(width: 140, height: 100)
        .background(isSelected ? color : Color.gray.opacity(0.4))
        .cornerRadius(20)
        .shadow(radius: 5)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut, value: isSelected)
        .onTapGesture { action() }
    }
}

struct LevelCard: View {
    var title: String
    var color: Color
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 100, height: 50)
            .background(isSelected ? color : Color.gray.opacity(0.4))
            .cornerRadius(15)
            .shadow(radius: 3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut, value: isSelected)
            .onTapGesture { action() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
