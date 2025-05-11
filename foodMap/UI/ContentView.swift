import SwiftUI


struct ContentView: View {
    @State private var showLogin = false
    
    var body: some View {
        if showLogin {
            LoginView(showLogin: $showLogin)
        } else {
            SignUpView(showLogin: $showLogin)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
