//
//  ContentView.swift
//  CoCho
//
//  Created by Erik Valigurský on 17/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothAudioManager()
    
    var body: some View {
        let _ = print("ContentView sa renderuje")
        VStack(spacing: 20) {
            Text("Codec Choser (CoCho)")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            // Pripojené zariadenia
            VStack(alignment: .leading, spacing: 10) {
                Text("Pripojené slúchadlá:")
                    .font(.headline)
                
                if bluetoothManager.connectedDevices.isEmpty {
                    Text("Žiadne zariadenia")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(bluetoothManager.connectedDevices, id: \.self) { device in
                        HStack {
                            Image(systemName: "headphones")
                            Text(device)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Aktuálny kodek
            VStack(alignment: .leading, spacing: 10) {
                Text("Aktuálny kodek:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "waveform")
                    Text(bluetoothManager.currentCodec)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Prepínanie kodekov
            VStack(alignment: .leading, spacing: 10) {
                Text("Dostupné kodeky:")
                    .font(.headline)
                
                ForEach(bluetoothManager.availableCodecs, id: \.self) { codec in
                    Button(action: {
                        bluetoothManager.switchCodec(to: codec)
                    }) {
                        HStack {
                            Image(systemName: codec == bluetoothManager.currentCodec ? "checkmark.circle.fill" : "circle")
                            Text(codec)
                            Spacer()
                        }
                        .padding()
                        .background(codec == bluetoothManager.currentCodec ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button("Obnoviť") {
                bluetoothManager.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}

