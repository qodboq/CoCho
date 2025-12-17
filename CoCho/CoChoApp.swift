//
//  CoChoApp.swift
//  CoCho
//
//  Created by Erik Valigurský on 17/12/2025.
//

import SwiftUI
import CoreBluetooth
import IOBluetooth
import Combine

@main
struct BluetoothAudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}


// Class for bluetoothAudioManager
class BluetoothAudioManager: NSObject, ObservableObject {
    @Published var connectedDevices: [String] = []
    @Published var currentCodec: String = "Neznámy"
    @Published var availableCodecs: [String] = ["SBC", "AAC", "aptX", "aptX HD", "LDAC"]
    
    override init() {
        super.init()
        print("🚀 BluetoothAudioManager sa inicializuje...")
        refresh()
        print("🔄 Volám refresh()...")
        
        // Sledovanie zmien v Bluetooth zariadeniach
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceConnected),
            name: NSNotification.Name(rawValue: "IOBluetoothDeviceConnectedNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceDisconnected),
            name: NSNotification.Name(rawValue: "IOBluetoothDeviceDisconnectedNotification"),
            object: nil
        )
        print("✅ BluetoothAudioManager inicializovaný")
    }
    
    // Refresh Function
    func refresh() {
        print("🔄 refresh() zavolaný")
        updateConnectedDevices()
        updateCurrentCodec()
    }

    // Update Connected Bluetooth Devices
    private func updateConnectedDevices() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 Začínam hľadať zariadenia...")
            var devices: [String] = []
            
            let pairedDevices = IOBluetoothDevice.pairedDevices()
            print("📱 Počet spárovaných zariadení: \(pairedDevices?.count ?? 0)")
            
            if let pairedDevices = pairedDevices as? [IOBluetoothDevice] {
                for device in pairedDevices {
                    print("🎧 Zariadenie: \(device.name ?? "bez mena"), pripojené: \(device.isConnected())")
                    
                    // Filter: len audio zariadenia
                    if device.isConnected() && self.isAudioDevice(device) {  // ← pridaj filter
                        if let name = device.name {
                            devices.append(name)
                        }
                    }
                }
            }
            
            print("✅ Nájdené pripojené slúchadlá: \(devices)")
            
            DispatchQueue.main.async {
                self.connectedDevices = devices
            }
        }
    }

    // Update Currently used Codec
    private func updateCurrentCodec() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                for device in pairedDevices {
                    if device.isConnected() && self.isAudioDevice(device) {
                        // Skús zistiť kodek z logov
                        let codec = self.detectCodecFromLogs()
                        print("🎵 Detekovaný kodek: \(codec)")
                        
                        DispatchQueue.main.async {
                            self.currentCodec = codec
                        }
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.currentCodec = "Žiadne zariadenie"
            }
        }
    }
// Detect Codec
    private func detectCodec(for device: IOBluetoothDevice) -> String {
        // Detekcia kodeku na základe služieb a vlastností zariadenia
        // Toto je zjednodušená implementácia
        
        if let services = device.services as? [IOBluetoothSDPServiceRecord] {
            for service in services {
                // Kontrola A2DP profilu
                if let serviceName = service.getServiceName() {
                    if serviceName.contains("A2DP") || serviceName.contains("Audio") {
                        // Predvolený kodek pre väčšinu zariadení je AAC na macOS
                        return "AAC"
                    }
                }
            }
        }
        
        return "ACC" // Základný kodek
    }
    
    // Zistí, či je zariadenie audio (slúchadlá, reproduktory)
    private func isAudioDevice(_ device: IOBluetoothDevice) -> Bool {
        // Skontroluj Class of Device (CoD)
        let cod = device.classOfDevice
        
        // Audio zariadenia majú major service class 0x200000 (Audio)
        // alebo major device class 0x0400 (Audio/Video)
        let majorServiceClass = (cod & 0xFFE000) >> 13
        let majorDeviceClass = (cod & 0x1F00) >> 8
        
        // Audio service alebo Audio/Video device
        if majorServiceClass & 0x08 != 0 || majorDeviceClass == 0x04 {
            return true
        }
        
        // Alternatívne: skontroluj služby
        if let services = device.services as? [IOBluetoothSDPServiceRecord] {
            for service in services {
                if let serviceName = service.getServiceName() {
                    if serviceName.contains("Audio") ||
                       serviceName.contains("A2DP") ||
                       serviceName.contains("Headset") ||
                       serviceName.contains("Handsfree") {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
// Find Codec in Logs
    private func detectCodecFromLogs() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = [
            "show",
            "--predicate", "subsystem contains 'bluetooth' AND eventMessage contains 'A2DP configured'",
            "--last", "1h",
            "--style", "compact"
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("📋 A2DP logy:\n\(output)")
                
                // Parsuj kodek z "Codec: XXX"
                if let range = output.range(of: "Codec: ([A-Za-z0-9-]+)", options: .regularExpression) {
                    let codecString = String(output[range])
                    let codec = codecString.replacingOccurrences(of: "Codec: ", with: "")
                    
                    // Zjednodušené názvy
                    if codec.contains("AAC") {
                        return "AAC"
                    } else if codec.contains("aptX HD") {
                        return "aptX HD"
                    } else if codec.contains("aptX") {
                        return "aptX"
                    } else if codec.contains("LDAC") {
                        return "LDAC"
                    } else if codec.contains("SBC") {
                        return "SBC"
                    }
                    
                    return codec  // Vráť presný názov (napr. "AAC-LC")
                }
            }
        } catch {
            print("❌ Chyba pri čítaní logov: \(error)")
        }
        
        return "Neznámy"
    }
    
    
// Switch Current Codec, it is possible it won't work
    func switchCodec(to codec: String) {
        // Prepnutie kodeku - toto vyžaduje nízkoúrovňový prístup k Bluetooth stacku
        // Na macOS je toto obmedzené a nemusí byť vždy možné
        
        print("Pokus o prepnutie na kodek: \(codec)")
        
        // Simulácia prepnutia (v reálnej aplikácii by to vyžadovalo privilégovaný prístup)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentCodec = codec
        }
        
        // Poznámka: Skutočné prepínanie kodekov na macOS vyžaduje:
        // 1. Prístup k CoreAudio API
        // 2. Možno aj súkromné API alebo system extensions
        // 3. Niektoré zariadenia nepodporujú manuálne prepínanie
    }
    // Callback Function for notifications
    @objc private func deviceConnected() {
        refresh()
    }
    
    @objc private func deviceDisconnected() {
        refresh()
    }
    // Will prevent memmory leaks
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

