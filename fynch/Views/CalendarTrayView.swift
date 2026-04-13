import SwiftUI

struct CalendarTrayView: View {
    @Binding var isExpanded: Bool
    var onDateTap: ((Date) -> Void)? = nil

    @Environment(AppState.self) private var appState
    @State private var dragOffset: CGFloat = 0
    @State private var displayedMonth: Date = Self.startOfCurrentMonth()

    static let handleBarHeight: CGFloat = 28

    // MARK: - Body

    private static let expandedHeight: CGFloat = 320

    var body: some View {
        VStack(spacing: 0) {
            handleArea
            if isExpanded {
                calendarContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(height: isExpanded ? Self.expandedHeight : Self.handleBarHeight, alignment: .top)
        .background(
            .ultraThinMaterial,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 16
            )
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: -2)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
    }

    // MARK: - Handle

    private var handleArea: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.handleBarHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .gesture(dragGesture)
    }

    // MARK: - Drag

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let t = value.translation.height
                dragOffset = isExpanded ? max(0, t) : min(0, t)
            }
            .onEnded { value in
                let t = value.translation.height
                let v = value.velocity.height
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    if isExpanded {
                        if t > 80 || v > 300 { isExpanded = false }
                    } else {
                        if t < -80 || v < -300 { isExpanded = true }
                    }
                    dragOffset = 0
                }
            }
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack(spacing: 4) {
            monthHeader
            weekdayLabels
            dayGrid
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 44)

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 4)
    }

    private var weekdayLabels: some View {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return HStack(spacing: 0) {
            ForEach(symbols.indices, id: \.self) { i in
                Text(symbols[i])
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let airingDates = appState.allAiringDates()
        let cal = Calendar.current
        let leading = cal.component(.weekday, from: displayedMonth) - 1
        let days = cal.range(of: .day, in: .month, for: displayedMonth)!.count
        let total = leading + days
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        let todayISO = Self.cellFormatter.string(from: Date())

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                if i < leading {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                } else {
                    let day = i - leading + 1
                    let date = self.date(day: day)
                    let iso = date.map { Self.cellFormatter.string(from: $0) } ?? ""
                    let isAiring = !iso.isEmpty && airingDates.contains(iso)
                    let isPast = iso < todayISO

                    ZStack {
                        if isAiring {
                            if isPast {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            } else {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        Text("\(day)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(
                                isAiring ? (isPast ? Color.accentColor : .white) : .primary
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let d = date { onDateTap?(d) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = next }
    }

    private func date(day: Int) -> Date? {
        var comps = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        return Calendar.current.date(from: comps)
    }

    private static func startOfCurrentMonth() -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }

    private static let cellFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
