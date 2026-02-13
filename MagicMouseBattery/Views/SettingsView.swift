import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuración")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Notificación de batería baja")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(notificationService.notificationThreshold) },
                            set: { notificationService.notificationThreshold = Int($0) }
                        ),
                        in: 5...50,
                        step: 5
                    )

                    Text("\(notificationService.notificationThreshold)%")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 40)
                }

                Text("Se notificará cuando la batería baje del \(notificationService.notificationThreshold)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button("Reiniciar notificaciones") {
                    notificationService.resetNotifiedDevices()
                }
                .buttonStyle(.borderless)

                Text("Fuerza el reinicio de las notificaciones para todos los dispositivos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 280)
    }
}
