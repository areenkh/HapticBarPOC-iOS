import SwiftUI
import CoreHaptics

struct ContentView: View {
    private let values: [CGFloat] = [0.2, 0.65, 0.4, 0.85, 0.55]
    @State private var activeIndex: Int? = nil

    @State private var engine: CHHapticEngine? = nil

    var body: some View {
        GeometryReader { geo in
            let padding: CGFloat = 24
            let innerW = geo.size.width - padding*2
            let innerH = geo.size.height - padding*2
            let gap: CGFloat = 12
            let barW = (innerW - gap * CGFloat(values.count - 1)) / CGFloat(values.count)

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(activeIndex.map { "On bar \($0)" } ?? "Touch a bar")
                        .font(.headline)

                    HStack(alignment: .bottom, spacing: gap) {
                        ForEach(values.indices, id: \.self) { i in
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: barW, height: values[i] * innerH)
                        }
                    }
                    .frame(width: innerW, height: innerH, alignment: .bottom)
                    .padding(padding)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                let p = g.location
                                let idx = hitTest(point: p,
                                                  size: geo.size,
                                                  padding: padding,
                                                  gap: gap,
                                                  values: values)
                                if idx != activeIndex {
                                    activeIndex = idx
                                    if idx != nil { hapticTap() }
                                }
                            }
                            .onEnded { _ in activeIndex = nil }
                    )
                }
            }
            .onAppear { prepareHaptics() }
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    private func hapticTap() {
        guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let i = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let event = CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [i, s],
                                  relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch { }
    }

    private func hitTest(point: CGPoint,
                         size: CGSize,
                         padding: CGFloat,
                         gap: CGFloat,
                         values: [CGFloat]) -> Int? {
        let innerW = size.width - padding*2
        let innerH = size.height - padding*2
        guard innerW > 0, innerH > 0 else { return nil }

        let x = point.x - padding
        let y = point.y - padding
        if x < 0 || y < 0 || x > innerW || y > innerH { return nil }

        let barW = (innerW - gap * CGFloat(values.count - 1)) / CGFloat(values.count)

        for i in values.indices {
            let barX = CGFloat(i) * (barW + gap)
            let barH = values[i] * innerH
            let barY = innerH - barH
            let rect = CGRect(x: barX, y: barY, width: barW, height: barH)
            if rect.contains(CGPoint(x: x, y: y)) { return i }
        }
        return nil
    }
}
