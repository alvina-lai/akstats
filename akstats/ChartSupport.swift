import SwiftUI
import Charts

// MARK: - Seeded random numbers

/// A small deterministic generator (SplitMix64) so every example chart is identical each time it's drawn.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A uniform value in [0, 1).
    mutating func uniform() -> Double {
        Double(next() >> 11) / 9_007_199_254_740_992.0   // 2^53
    }

    /// A normal value via the Box–Muller transform.
    mutating func normal(_ mean: Double = 0, _ sd: Double = 1) -> Double {
        let u1 = max(uniform(), 1e-12)
        let u2 = uniform()
        return mean + sd * (-2 * log(u1)).squareRoot() * cos(2 * .pi * u2)
    }
}

// MARK: - Small statistics helpers

enum Stats {
    static func mean(_ x: [Double]) -> Double { x.reduce(0, +) / Double(x.count) }

    static func sd(_ x: [Double]) -> Double {
        let m = mean(x)
        return (x.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(x.count - 1)).squareRoot()
    }

    static func quantile(_ x: [Double], _ p: Double) -> Double {
        let sorted = x.sorted()
        let position = p * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = min(lower + 1, sorted.count - 1)
        let fraction = position - Double(lower)
        return sorted[lower] + fraction * (sorted[upper] - sorted[lower])
    }

    /// Standard normal CDF.
    static func phi(_ z: Double) -> Double { 0.5 * (1 + erf(z / 2.squareRoot())) }

    /// Standard normal density.
    static func density(_ z: Double) -> Double { exp(-z * z / 2) / (2 * .pi).squareRoot() }

    /// Inverse standard normal CDF by bisection (accurate enough for plotting).
    static func inversePhi(_ p: Double) -> Double {
        var low = -8.0, high = 8.0
        for _ in 0..<60 {
            let mid = (low + high) / 2
            if phi(mid) < p { low = mid } else { high = mid }
        }
        return (low + high) / 2
    }

    static func logistic(_ x: Double) -> Double { 1 / (1 + exp(-x)) }

    static func correlation(_ x: [Double], _ y: [Double]) -> Double {
        let mx = mean(x), my = mean(y)
        let sxy = zip(x, y).map { ($0 - mx) * ($1 - my) }.reduce(0, +)
        let sxx = x.map { ($0 - mx) * ($0 - mx) }.reduce(0, +)
        let syy = y.map { ($0 - my) * ($0 - my) }.reduce(0, +)
        return sxy / (sxx * syy).squareRoot()
    }

    /// Least-squares intercept and slope.
    static func fitLine(_ x: [Double], _ y: [Double]) -> (intercept: Double, slope: Double) {
        let mx = mean(x), my = mean(y)
        let sxy = zip(x, y).map { ($0 - mx) * ($1 - my) }.reduce(0, +)
        let sxx = x.map { ($0 - mx) * ($0 - mx) }.reduce(0, +)
        let slope = sxy / sxx
        return (my - slope * mx, slope)
    }
}

/// One histogram bar.
struct HistogramBin: Identifiable {
    let low: Double
    let high: Double
    let count: Int
    var id: Double { low }
    var mid: Double { (low + high) / 2 }
}

extension Stats {
    static func histogram(_ values: [Double], from low: Double, to high: Double, width: Double) -> [HistogramBin] {
        let n = Int(((high - low) / width).rounded())
        var counts = Array(repeating: 0, count: n)
        for v in values where v >= low && v < high {
            counts[min(Int((v - low) / width), n - 1)] += 1
        }
        return counts.indices.map { HistogramBin(low: low + Double($0) * width, high: low + Double($0 + 1) * width, count: counts[$0]) }
    }
}

// MARK: - Palette and styling

/// Series colors chosen to read well on the dark surfaces and for colorblind viewers
/// (Okabe–Ito hues, lightened for dark mode). Assigned in this fixed order.
enum ChartPalette {
    static let sky = Color(hex: 0x56B4E9)
    static let orange = Color(hex: 0xE69F00)
    static let pink = Color(hex: 0xCC79A7)
    static let muted = Color(hex: 0x64748B)
    static let series: [Color] = [sky, orange, pink]
}

extension View {
    /// Recessive axes and gridlines in the app's dark palette.
    func statChartAxes() -> some View {
        self
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                    AxisTick().foregroundStyle(Theme.hairline)
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                    AxisTick().foregroundStyle(Theme.hairline)
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
    }
}

/// A floating readout used by hover layers.
struct ChartReadout: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Theme.background.opacity(0.92), in: .rect(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline) }
    }
}

// MARK: - Container

/// Wraps an example chart with its title and a “How to read it” guide.
struct ChartExampleView: View {
    let example: ChartExample

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Reading the data", systemImage: "chart.xyaxis.line")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                Text(example.title)
                    .font(.title3.weight(.semibold))
                Text("Simulated example data · hover over the chart to see values")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ChartKindView(kind: example.kind)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Label("How to read it", systemImage: "eye")
                    .font(.headline)
                ForEach(example.reading.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                        markdown(example.reading[index])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .card(padding: 20)
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}

/// Picks the chart view for a kind.
struct ChartKindView: View {
    let kind: ChartKind

    var body: some View {
        switch kind {
        case .skewedDistribution: SkewedDistributionChart()
        case .boxplotComparison: BoxplotComparisonChart()
        case .normalCurve: NormalCurveChart()
        case .qqPlot: QQPlotChart()
        case .confidenceIntervals: ConfidenceIntervalsChart()
        case .nullDistribution: NullDistributionChart()
        case .bootstrapDistribution: BootstrapDistributionChart()
        case .powerCurves: PowerCurvesChart()
        case .pairedLines: PairedLinesChart()
        case .groupMeans: GroupMeansChart()
        case .interactionMeans: InteractionMeansChart()
        case .ancovaLines: AncovaLinesChart()
        case .contingencyBars: ContingencyBarsChart()
        case .correlationGallery: CorrelationGalleryChart()
        case .betweenWithin: BetweenWithinChart()
        case .regressionResiduals: RegressionResidualsChart()
        case .residualPlots: ResidualPlotsChart()
        case .coefficientPlot: CoefficientPlotChart()
        case .logisticCurve: LogisticCurveChart()
        case .randomEffects: RandomEffectsChart()
        case .agreementTable: AgreementTableChart()
        case .simpleSlopes: SimpleSlopesChart()
        case .ordinalShares: OrdinalSharesChart()
        case .transitionHeatmap: TransitionHeatmapChart()
        case .classProfiles: ClassProfilesChart()
        case .profileMeans: ProfileMeansChart()
        }
    }
}
