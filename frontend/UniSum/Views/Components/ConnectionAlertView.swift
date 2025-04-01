import SwiftUI

struct ConnectionAlertView: View {
    @ObservedObject var networkManager: NetworkManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundColor(iconColor)
            
            Text(titleKey)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(messageKey)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if networkManager.connectionErrorType == .filtered {
                Button(action: {
                    if let url = URL(string: "https://www.hotspotshield.com/tr/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("connection_alert_use_vpn")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                networkManager.dismissConnectionAlert()
            }) {
                Text("connection_alert_close")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
    
    private var iconName: String {
        switch networkManager.connectionErrorType {
        case .noConnection:
            return "wifi.slash"
        case .filtered:
            return "shield.slash"
        case .serverError:
            return "exclamationmark.icloud"
        case .other:
            return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch networkManager.connectionErrorType {
        case .filtered:
            return .orange
        default:
            return .red
        }
    }
    
    private var titleKey: LocalizedStringKey {
        switch networkManager.connectionErrorType {
        case .noConnection:
            return "connection_error_no_connection_title"
        case .filtered:
            return "connection_error_filtered_title"
        case .serverError:
            return "connection_error_server_title"
        case .other:
            return "connection_error_other_title"
        }
    }
    
    private var messageKey: LocalizedStringKey {
        switch networkManager.connectionErrorType {
        case .noConnection:
            return "connection_error_no_connection_message"
        case .filtered:
            return "connection_error_filtered_message"
        case .serverError:
            return "connection_error_server_message"
        case .other:
            return "connection_error_other_message"
        }
    }
} 