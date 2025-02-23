//
//  ContentView.swift
//  Tools-iPad
//
//  Created by Jago Lourenco-Goddard on 2/20/25.
//

import SwiftUI



struct MainAppView: View {
    
    @State private var windowSize: CGSize = .zero
#if os(macOS)
    private func updateWindowSize() {
        if let window = NSApplication.shared.windows.first {
            windowSize = window.frame.size
        }
    }


        let currentOS = "macOS"
#elseif os(iOS)
        let currentOS = "iPad"
#endif
    var body: some View {

            NavigationStack {
                ScrollView{
                    VStack{
                        VStack{
                            Image("PSToolsLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.top)
                                .padding(.bottom, 0)
                                .frame(maxWidth: 500, maxHeight: 100)
                            HStack(alignment: .lastTextBaseline){
                                Text("Pullscription™ Tools for \(currentOS)")
                                    .font(.title2)
                                    .bold()
                                    .padding(.bottom, 0)
                                Text("v. \(Bundle.main.versionNumber)")
                                    .font(.caption)
#if os(macOS)
                                VStack{
                                    Text("Width: \(Int(windowSize.width))")
                                    Text("Height: \(Int(windowSize.height))")
                                }
#endif
                            }
                        }
                        .padding()
                        
                        VStack {
                            HStack{
                                NavigationLink(destination: CardLookup()) {
                                    VStack {
                                        Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                                            .font(.system(size: 75))
                                            .foregroundColor(.white)
                                            .padding()
                                        Text("Card Lookup")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                        
                                    }
                                    .padding()
                                    .frame(width: 300, height: 300) // Makes it big and buttony
                                    .background(Color.blue) // Background color
                                    .cornerRadius(12) // Rounded corners
                                    .shadow(radius: 5) // Slight shadow for depth
                                }
                                .buttonStyle(.plain) // Removes default NavigationLink styling
                                .padding()
                                NavigationLink(destination: ShipmentCheckIn()) {
                                    VStack {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                            .font(.system(size: 75))
                                            .foregroundColor(.white)
                                            .padding()
                                        Text("Shipment Check-In")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                        
                                    }
                                    .padding()
                                    .frame(width: 300, height: 300) // Makes it big and buttony
                                    .background(Color.blue) // Background color
                                    .cornerRadius(12) // Rounded corners
                                    .shadow(radius: 5) // Slight shadow for depth
                                }
                                .buttonStyle(.plain) // Removes default NavigationLink styling
                                .padding()
                            }
                            HStack{
                                NavigationLink(destination: SplitShipment()) {
                                    VStack {
                                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                                            .font(.system(size: 75))
                                            .foregroundColor(.white)
                                            .padding()
                                        Text("Split Shipment")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                        
                                    }
                                    .padding()
                                    .frame(maxWidth: 300, minHeight: 300) // Makes it big and buttony
                                    .background(Color.blue) // Background color
                                    .cornerRadius(12) // Rounded corners
                                    .shadow(radius: 5) // Slight shadow for depth
                                }
                                .buttonStyle(.plain) // Removes default NavigationLink styling
                                .padding()
                                NavigationLink(destination: DataExport()) {
                                    VStack {
                                        Image(systemName: "square.and.arrow.down.on.square")
                                            .font(.system(size: 75))
                                            .foregroundColor(.white)
                                            .padding()
                                        Text("Data Export")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                        
                                    }
                                    .padding()
                                    .frame(width: 300, height: 300) // Makes it big and buttony
                                    .background(Color.blue) // Background color
                                    .cornerRadius(12) // Rounded corners
                                    .shadow(radius: 5) // Slight shadow for depth
                                }
                                .buttonStyle(.plain) // Removes default NavigationLink styling
                                .padding()
                            }
                            .navigationTitle("Home")
                        }
                    }
                }
        }.onAppear(){
                #if os(macOS)
                resizeWindow(width: 700, height: 900)
                
            updateWindowSize()
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: nil,
                queue: .main
            ) { _ in
                updateWindowSize()
            }
#endif
        }
    }
}

#Preview {
    MainAppView()
}
