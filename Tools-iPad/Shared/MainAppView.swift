//
//  ContentView.swift
//  Tools-iPad
//
//  Created by Jago Lourenco-Goddard on 2/20/25.
//

import SwiftUI

struct MainAppView: View {
    var body: some View {
#if os(macOS)
        let currentOS = "macOS"
#elseif os(iOS)
        let currentOS = "iPad"
#endif
        VStack{
            Image("PSToolsLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top)
                .padding(.bottom, 0)
                .frame(maxWidth: 500)
            HStack(alignment: .lastTextBaseline){
                Text("Pullscription™ Tools for \(currentOS)")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 0)
                Text("v. \(Bundle.main.versionNumber)")
                    .font(.caption)
            }
        }
        .padding()
        NavigationStack {
            VStack {
                NavigationLink(destination: CardLookup()) {
                    VStack {
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                            .font(.system(size: 75))
                            .foregroundColor(.white)
                        Text("Card Lookup")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            
                    }
                    .padding()
                    .frame(maxWidth: 200, minHeight: 200) // Makes it big and buttony
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

#Preview {
    MainAppView()
}
