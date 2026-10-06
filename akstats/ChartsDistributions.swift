import SwiftUI
import Charts

// Example charts for describing data and for inference (Units 2–3).

// MARK: - Skewed distribution: mean vs. median

struct SkewedDistributionChart: View {
    private static let values: [Double] = {
        var rng = SeededGenerator(seed: 11)
        return (0..<500).map { _ in exp(rng.normal(6.2, 0.35)) }
    }()
    private static let bins = Stats.histogram(values, from: 200, to: 1400, width: 50)
    private static let mean = Stats.mean(values)
    private static let median = Stats.quantile(values, 0.5)

    @State private var selectedX: Double?

    private var selectedBin: HistogramBin? {
        guard let x = selectedX else { return nil }
        return Self.bins.first { x >= $0.low && x < $0.high }
    }

    var body: some View {
        Chart {
            ForEach(Self.bins) { bin in
                RectangleMark(xStart: .value("Low", bin.low + 2), xEnd: .value("High", bin.high - 2), yStart: .value("Responses", 0), yEnd: .value("Responses", bin.count))
                    .foregroundStyle(ChartPalette.sky.opacity(selectedBin?.id == bin.id ? 1 : 0.7))
            }
            RuleMark(x: .value("Median", Self.median))
                .foregroundStyle(ChartPalette.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Median \(Int(Self.median)) ms").font(.caption.weight(.semibold)).foregroundStyle(ChartPalette.orange)
                }
            RuleMark(x: .value("Mean", Self.mean))
                .foregroundStyle(ChartPalette.pink)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Mean \(Int(Self.mean)) ms").font(.caption.weight(.semibold)).foregroundStyle(ChartPalette.pink)
                }
            if let bin = selectedBin {
                RuleMark(x: .value("Selected", bin.mid))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: ["\(Int(bin.low))–\(Int(bin.high)) ms", "\(bin.count) responses"])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXAxisLabel("Reaction time (ms)")
        .chartYAxisLabel("Responses")
        .statChartAxes()
        .frame(height: 250)
        .accessibilityLabel("Histogram of 500 right-skewed reaction times; mean \(Int(Self.mean)) ms, median \(Int(Self.median)) ms")
    }
}

// MARK: - Boxplots with raw points

struct BoxplotComparisonChart: View {
    private struct Group: Identifiable {
        let id: Int
        let name: String
        let values: [Double]
        let jitter: [Double]
        var q1: Double { Stats.quantile(values, 0.25) }
        var median: Double { Stats.quantile(values, 0.5) }
        var q3: Double { Stats.quantile(values, 0.75) }
        var lowWhisker: Double { values.filter { $0 >= q1 - 1.5 * (q3 - q1) }.min() ?? q1 }
        var highWhisker: Double { values.filter { $0 <= q3 + 1.5 * (q3 - q1) }.max() ?? q3 }
    }

    private static let groups: [Group] = {
        var rng = SeededGenerator(seed: 21)
        func make(_ id: Int, _ name: String, _ draw: (inout SeededGenerator) -> Double) -> Group {
            let values = (0..<40).map { _ in draw(&rng) }
            return Group(id: id, name: name, values: values, jitter: values.map { _ in rng.uniform() * 0.36 - 0.18 })
        }
        return [
            make(0, "Lecture") { $0.normal(64, 8) },
            make(1, "Active") { $0.normal(70, 8) },
            make(2, "Flipped") { 56 + exp($0.normal(2.2, 0.6)) },
        ]
    }()

    @State private var selectedX: Double?

    private var selectedGroup: Group? {
        guard let x = selectedX else { return nil }
        return Self.groups.min { abs(Double($0.id) - x) < abs(Double($1.id) - x) }
    }

    var body: some View {
        Chart {
            ForEach(Self.groups) { group in
                let x = Double(group.id)
                RuleMark(x: .value("Group", x), yStart: .value("Low", group.lowWhisker), yEnd: .value("High", group.highWhisker))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                RectangleMark(xStart: .value("Left", x - 0.22), xEnd: .value("Right", x + 0.22),
                              yStart: .value("Q1", group.q1), yEnd: .value("Q3", group.q3))
                    .foregroundStyle(ChartPalette.series[group.id].opacity(0.25))
                RuleMark(xStart: .value("Left", x - 0.22), xEnd: .value("Right", x + 0.22), y: .value("Median", group.median))
                    .foregroundStyle(ChartPalette.series[group.id])
                    .lineStyle(StrokeStyle(lineWidth: 3))
                ForEach(group.values.indices, id: \.self) { i in
                    PointMark(x: .value("Group", x + group.jitter[i]), y: .value("Score", group.values[i]))
                        .foregroundStyle(ChartPalette.series[group.id].opacity(0.7))
                        .symbolSize(18)
                }
            }
            if let group = selectedGroup {
                RuleMark(x: .value("Selected", Double(group.id)))
                    .foregroundStyle(.clear)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [group.name,
                                             String(format: "Median %.1f", group.median),
                                             String(format: "IQR %.1f – %.1f", group.q1, group.q3)])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXScale(domain: -0.6...2.6)
        .chartXAxis {
            AxisMarks(values: [0.0, 1.0, 2.0]) { value in
                AxisValueLabel {
                    if let i = value.as(Double.self) { Text(Self.groups[Int(i)].name).foregroundStyle(Theme.textSecondary) }
                }
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                AxisValueLabel().foregroundStyle(Theme.textSecondary)
            }
        }
        .chartYScale(domain: 35...110)
        .chartYAxisLabel("Post-test score")
        .frame(height: 260)
    }
}

// MARK: - Normal curve with SD bands

struct NormalCurveChart: View {
    private struct Segment: Identifiable {
        let id: String
        let from: Double
        let to: Double
        let opacity: Double
    }

    private static let segments: [Segment] = [
        Segment(id: "−3 to −2", from: -3, to: -2, opacity: 0.15),
        Segment(id: "−2 to −1", from: -2, to: -1, opacity: 0.35),
        Segment(id: "−1 to 1", from: -1, to: 1, opacity: 0.65),
        Segment(id: "1 to 2", from: 1, to: 2, opacity: 0.35),
        Segment(id: "2 to 3", from: 2, to: 3, opacity: 0.15),
    ]
    private static let curve: [Double] = stride(from: -3.6, through: 3.6, by: 0.05).map { $0 }

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.segments) { segment in
                ForEach(Array(stride(from: segment.from, through: segment.to, by: 0.05)), id: \.self) { z in
                    AreaMark(x: .value("z", z), yStart: .value("Base", 0), yEnd: .value("Density", Stats.density(z)), series: .value("Band", segment.id))
                        .foregroundStyle(Theme.accent.opacity(segment.opacity))
                }
            }
            ForEach(Self.curve, id: \.self) { z in
                LineMark(x: .value("z", z), y: .value("Density", Stats.density(z)))
                    .foregroundStyle(Theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            PointMark(x: .value("z", 0), y: .value("Density", 0.17)).symbolSize(1).foregroundStyle(Color.clear)
                .annotation(position: .overlay) { Text("68%").font(.callout.weight(.bold)).foregroundStyle(Theme.onAccent) }
            PointMark(x: .value("z", 1.5), y: .value("Density", 0.06)).symbolSize(1).foregroundStyle(Color.clear)
                .annotation(position: .overlay) { Text("13.5%").font(.caption).foregroundStyle(Theme.textPrimary) }
            PointMark(x: .value("z", -1.5), y: .value("Density", 0.06)).symbolSize(1).foregroundStyle(Color.clear)
                .annotation(position: .overlay) { Text("13.5%").font(.caption).foregroundStyle(Theme.textPrimary) }
            if let x = selectedX {
                RuleMark(x: .value("Selected", x))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [String(format: "z = %.2f", x),
                                             String(format: "%.1f%% fall below", 100 * Stats.phi(x))])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXScale(domain: -3.6...3.6)
        .chartXAxisLabel("z (standard deviations from the mean)")
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: [-3, -2, -1, 0, 1, 2, 3]) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                AxisValueLabel().foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(height: 230)
    }
}

// MARK: - Q–Q plot

struct QQPlotChart: View {
    private struct QQPoint: Identifiable {
        let id = UUID()
        let theoretical: Double
        let sample: Double
        let series: String
    }

    private static let points: [QQPoint] = {
        var rng = SeededGenerator(seed: 31)
        func standardized(_ x: [Double]) -> [Double] {
            let m = Stats.mean(x), s = Stats.sd(x)
            return x.map { ($0 - m) / s }.sorted()
        }
        let normal = standardized((0..<80).map { _ in rng.normal() })
        let skewed = standardized((0..<80).map { _ in exp(rng.normal(0, 0.7)) })
        var points: [QQPoint] = []
        for i in 0..<80 {
            let q = Stats.inversePhi((Double(i) + 0.5) / 80)
            points.append(QQPoint(theoretical: q, sample: normal[i], series: "Roughly normal"))
            points.append(QQPoint(theoretical: q, sample: skewed[i], series: "Right-skewed"))
        }
        return points
    }()

    var body: some View {
        Chart {
            LineMark(x: .value("Theoretical", -2.6), y: .value("Sample", -2.6), series: .value("Line", "Reference"))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            LineMark(x: .value("Theoretical", 2.6), y: .value("Sample", 2.6), series: .value("Line", "Reference"))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            ForEach(Self.points) { point in
                PointMark(x: .value("Theoretical", point.theoretical), y: .value("Sample", point.sample))
                    .foregroundStyle(by: .value("Data", point.series))
                    .symbolSize(24)
            }
        }
        .chartForegroundStyleScale(["Roughly normal": ChartPalette.sky, "Right-skewed": ChartPalette.orange])
        .chartLegend(position: .top, alignment: .leading)
        .chartXAxisLabel("Expected z (if normal)")
        .chartYAxisLabel("Observed z")
        .statChartAxes()
        .frame(height: 260)
    }
}

// MARK: - 25 confidence intervals

struct ConfidenceIntervalsChart: View {
    private struct Interval: Identifiable {
        let id: Int
        let mean: Double
        let low: Double
        let high: Double
        var covers: Bool { low <= 100 && 100 <= high }
    }

    private static let intervals: [Interval] = {
        var rng = SeededGenerator(seed: 8)   // a seed where 2 of 25 intervals miss, as expected by chance
        return (1...25).map { i in
            let sample = (0..<30).map { _ in rng.normal(100, 15) }
            let m = Stats.mean(sample)
            let half = 2.045 * Stats.sd(sample) / 30.0.squareRoot()
            return Interval(id: i, mean: m, low: m - half, high: m + half)
        }
    }()

    @State private var selectedY: Int?

    var body: some View {
        Chart {
            RuleMark(x: .value("True mean", 100))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top) { Text("True mean = 100").font(.caption).foregroundStyle(Theme.textSecondary) }
            ForEach(Self.intervals) { interval in
                let label = interval.covers ? "Contains the true mean" : "Misses the true mean"
                RuleMark(xStart: .value("Low", interval.low), xEnd: .value("High", interval.high), y: .value("Sample", interval.id))
                    .foregroundStyle(by: .value("Interval", label))
                    .lineStyle(StrokeStyle(lineWidth: selectedY == interval.id ? 4 : 2.5, lineCap: .round))
                PointMark(x: .value("Mean", interval.mean), y: .value("Sample", interval.id))
                    .foregroundStyle(by: .value("Interval", label))
                    .symbolSize(30)
            }
            if let id = selectedY, let interval = Self.intervals.first(where: { $0.id == id }) {
                PointMark(x: .value("Mean", interval.high), y: .value("Sample", id)).symbolSize(1).foregroundStyle(Color.clear)
                    .annotation(position: .trailing, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: ["Sample \(id)", String(format: "95%% CI [%.1f, %.1f]", interval.low, interval.high)])
                    }
            }
        }
        .chartYSelection(value: $selectedY)
        .chartForegroundStyleScale(["Contains the true mean": ChartPalette.sky, "Misses the true mean": ChartPalette.orange])
        .chartLegend(position: .bottom, alignment: .leading)
        .chartXScale(domain: 85...115)
        .chartXAxisLabel("Sample mean with 95% CI")
        .chartYAxis(.hidden)
        .statChartAxes()
        .frame(height: 300)
    }
}

// MARK: - Null distribution from a permutation test

struct NullDistributionChart: View {
    private static let observed = 5.4
    private static let null: [Double] = {
        var rng = SeededGenerator(seed: 41)
        return (0..<5000).map { _ in rng.normal(0, 2.5) }
    }()
    private static let bins = Stats.histogram(null, from: -10, to: 10, width: 0.5)
    private static let pValue = Double(null.filter { abs($0) >= observed }.count) / Double(null.count)

    @State private var selectedX: Double?

    private var selectedBin: HistogramBin? {
        guard let x = selectedX else { return nil }
        return Self.bins.first { x >= $0.low && x < $0.high }
    }

    var body: some View {
        Chart {
            ForEach(Self.bins) { bin in
                let extreme = abs(bin.mid) >= Self.observed
                RectangleMark(xStart: .value("Low", bin.low + 0.03), xEnd: .value("High", bin.high - 0.03), yStart: .value("Shuffles", 0), yEnd: .value("Shuffles", bin.count))
                    .foregroundStyle(extreme ? ChartPalette.orange : ChartPalette.muted.opacity(0.8))
            }
            RuleMark(x: .value("Observed", Self.observed))
                .foregroundStyle(ChartPalette.sky)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .annotation(position: .top, alignment: .leading) {
                    Text("Observed difference = \(Self.observed, specifier: "%.1f")").font(.caption.weight(.semibold)).foregroundStyle(ChartPalette.sky)
                }
            RuleMark(x: .value("Mirror", -Self.observed))
                .foregroundStyle(ChartPalette.sky.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            if let bin = selectedBin {
                RuleMark(x: .value("Selected", bin.mid))
                    .foregroundStyle(.clear)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [String(format: "Difference %.1f to %.1f", bin.low, bin.high), "\(bin.count) of 5,000 shuffles"])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXAxisLabel("Difference in means if group labels didn't matter (p ≈ \(String(format: "%.3f", Self.pValue)))")
        .chartYAxisLabel("Shuffles")
        .statChartAxes()
        .frame(height: 250)
    }
}

// MARK: - Bootstrap distribution of a median

struct BootstrapDistributionChart: View {
    private static let sample: [Double] = {
        var rng = SeededGenerator(seed: 51)
        return (0..<80).map { _ in exp(rng.normal(6.2, 0.35)) }
    }()
    private static let medians: [Double] = {
        var rng = SeededGenerator(seed: 52)
        return (0..<3000).map { _ in
            let resample = (0..<sample.count).map { _ in sample[Int(rng.uniform() * Double(sample.count))] }
            return Stats.quantile(resample, 0.5)
        }
    }()
    private static let low = Stats.quantile(medians, 0.025)
    private static let high = Stats.quantile(medians, 0.975)
    private static let observed = Stats.quantile(sample, 0.5)
    private static let bins = Stats.histogram(medians, from: 380, to: 620, width: 6)

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.bins) { bin in
                let inside = bin.mid >= Self.low && bin.mid <= Self.high
                RectangleMark(xStart: .value("Low", bin.low + 0.4), xEnd: .value("High", bin.high - 0.4), yStart: .value("Resamples", 0), yEnd: .value("Resamples", bin.count))
                    .foregroundStyle(inside ? ChartPalette.sky.opacity(0.8) : ChartPalette.muted.opacity(0.7))
            }
            RuleMark(x: .value("2.5th percentile", Self.low))
                .foregroundStyle(ChartPalette.orange).lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .annotation(position: .top, alignment: .trailing) { Text("2.5%: \(Int(Self.low))").font(.caption).foregroundStyle(ChartPalette.orange) }
            RuleMark(x: .value("97.5th percentile", Self.high))
                .foregroundStyle(ChartPalette.orange).lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .annotation(position: .top, alignment: .leading) { Text("97.5%: \(Int(Self.high))").font(.caption).foregroundStyle(ChartPalette.orange) }
            RuleMark(x: .value("Sample median", Self.observed))
                .foregroundStyle(ChartPalette.pink).lineStyle(StrokeStyle(lineWidth: 2))
            if let x = selectedX {
                RuleMark(x: .value("Selected", x))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        let share = Double(Self.medians.filter { $0 <= x }.count) / Double(Self.medians.count)
                        ChartReadout(lines: [String(format: "Median ≤ %.0f ms", x), String(format: "in %.0f%% of resamples", 100 * share)])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXAxisLabel("Median reaction time in each of 3,000 resamples (ms)")
        .chartYAxisLabel("Resamples")
        .statChartAxes()
        .frame(height: 250)
    }
}

// MARK: - Power curves

struct PowerCurvesChart: View {
    private struct PowerPoint: Identifiable {
        let id = UUID()
        let n: Int
        let power: Double
        let effect: String
    }

    private static let effects: [(String, Double)] = [("d = 0.2", 0.2), ("d = 0.5", 0.5), ("d = 0.8", 0.8)]

    private static func power(n: Int, d: Double) -> Double {
        let shift = d * (Double(n) / 2).squareRoot()
        return Stats.phi(shift - 1.96) + Stats.phi(-shift - 1.96)
    }

    private static let points: [PowerPoint] = effects.flatMap { label, d in
        stride(from: 5, through: 400, by: 5).map { PowerPoint(n: $0, power: power(n: $0, d: d), effect: label) }
    }

    @State private var selectedN: Int?

    var body: some View {
        Chart {
            RuleMark(y: .value("Target", 0.8))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, alignment: .trailing) { Text("80% power").font(.caption).foregroundStyle(Theme.textSecondary) }
            ForEach(Self.points) { point in
                LineMark(x: .value("n per group", point.n), y: .value("Power", point.power))
                    .foregroundStyle(by: .value("Effect size", point.effect))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            if let n = selectedN {
                let rounded = max(5, min(400, Int((Double(n) / 5).rounded()) * 5))
                RuleMark(x: .value("Selected", rounded))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: ["n = \(rounded) per group"] + Self.effects.map { label, d in
                            String(format: "%@: power %.2f", label, Self.power(n: rounded, d: d))
                        })
                    }
            }
        }
        .chartXSelection(value: $selectedN)
        .chartForegroundStyleScale(["d = 0.2": ChartPalette.pink, "d = 0.5": ChartPalette.orange, "d = 0.8": ChartPalette.sky])
        .chartLegend(position: .top, alignment: .leading)
        .chartYScale(domain: 0...1)
        .chartXAxisLabel("Participants per group")
        .chartYAxisLabel("Power (two-sided α = .05)")
        .statChartAxes()
        .frame(height: 260)
    }
}
