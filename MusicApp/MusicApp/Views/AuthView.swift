import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var artistName = ""
    @State private var isLoading = false
    @State private var showError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, artistName
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                VStack(spacing: 24) {
                    // Logo/Header
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Music Co-Creation")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("email@example.com", text: $email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Artist Name (Sign Up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Artist Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Your artist name", text: $artistName)
                                    .textFieldStyle(.plain)
                                    .focused($focusedField, equals: .artistName)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(GradientButtonStyle())
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && artistName.isEmpty))
                    .padding(.horizontal)
                    
                    // Social Sign In
                    VStack(spacing: 16) {
                        Text("or continue with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            // Google Sign In
                            Button(action: handleGoogleSignIn) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Google")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            // Apple Sign In
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: handleAppleSignIn
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Toggle Sign Up/Sign In
                    Button(action: { 
                        withAnimation {
                            isSignUp.toggle()
                            // Clear form
                            email = ""
                            password = ""
                            artistName = ""
                            focusedField = nil
                        }
                    }) {
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(.purple)
                                .bold()
                        }
                        .font(.callout)
                    }
                    .padding(.bottom, 40)
                }
                }
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(supabase.authError ?? "An unknown error occurred")
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    private func handleSubmit() {
        focusedField = nil
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await supabase.signUp(email: email, password: password, artistName: artistName)
                } else {
                    try await supabase.signIn(email: email, password: password)
                }
            } catch {
                showError = true
            }
            isLoading = false
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                try await supabase.signInWithGoogle()
            } catch {
                showError = true
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle Apple sign in
            // This would require additional setup with Supabase
            print("Apple sign in successful: \(authorization)")
        case .failure(let error):
            print("Apple sign in failed: \(error)")
            supabase.authError = error.localizedDescription
            showError = true
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
