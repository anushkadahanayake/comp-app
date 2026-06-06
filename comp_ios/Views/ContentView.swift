//
//  ContentView.swift
//  comp_ios
//
//  Created by ANUSHKA DAHANAYAKE on 2026-06-10.
//

import SwiftUI

struct ContentView: View {

    @StateObject var vm = GameViewModel()

    var body: some View {

        VStack(spacing: 20) {

            // Scores at the top
            Text("Score: \(vm.tapCount)")
                .font(.largeTitle)
                .bold()
            Text("High Score: \(vm.highScore)")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Timer
            Text("Time: \(vm.timeLeft)")
                .font(.title)

            // Game button
            Button(action: {
                vm.tapButton()
            }) {
                Circle()
                    .fill(vm.state == .running ? Color.blue : Color.gray)
                    .frame(width: 160, height: 160)
            }
            .disabled(vm.state != .running || vm.timeLeft <= 0)

            // Controls
            if vm.state == .idle {
                Button("Start") {
                    vm.startGame()
                }
                .buttonStyle(.borderedProminent)
            }

            if vm.state == .finished {
                VStack(spacing: 8) {
                    Text("Final Score: \(vm.tapCount)")
                        .font(.title2)
                        .bold()
                    Button("Play Again") {
                        vm.resetGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
