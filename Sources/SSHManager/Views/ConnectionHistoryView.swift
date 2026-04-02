import SwiftUI

struct ConnectionHistoryView: View {
    @ObservedObject var history = ConnectionHistory.shared
    @Binding var isPresented: Bool
    var onSelectHost: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 400, height: 450)
    }

    private var header: some View {
        HStack {
            Text("连接历史")
                .font(.title2)
            Spacer()
            Text("\(history.records.count) 条记录")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var content: some View {
        Group {
            if history.records.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无连接记录")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("测试连接后会自动记录历史")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            if !history.recentHosts.isEmpty {
                Section("最近连接") {
                    ForEach(history.recentHosts, id: \.self) { alias in
                        Button(action: { onSelectHost(alias); isPresented = false }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text(alias)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("所有记录") {
                ForEach(history.records) { record in
                    ConnectionRecordRow(record: record)
                }
            }
        }
        .listStyle(.inset)
    }

    private var footer: some View {
        HStack {
            Button("清除历史") {
                history.clear()
            }
            .foregroundColor(.red)

            Spacer()

            Button("完成") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ConnectionRecordRow: View {
    let record: ConnectionRecord

    var body: some View {
        HStack {
            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(record.success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.hostAlias)
                    .font(.headline)
                Text(record.hostname)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let latency = record.latency {
                    Text("\(String(format: "%.0f", latency * 1000))ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(record.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
