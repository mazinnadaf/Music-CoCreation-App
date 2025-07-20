import Foundation

enum SupabaseConfig {
    // IMPORTANT: Replace these with your actual Supabase project values
    // You can find these in your Supabase project settings under API
    static let url = "https://mpuzozdhltxfcozxsawo.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wdXpvemRobHR4ZmNvenhzYXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI3MDk1NDEsImV4cCI6MjA2ODI4NTU0MX0.IGxVrzFSTcJsaPjiNQ70XQjmkiKP1--UB8dzaasF728"
    
    // Validate configuration
    static var isConfigured: Bool {
        return !url.contains("YOUR_SUPABASE") && !anonKey.contains("YOUR_SUPABASE")
    }
}
