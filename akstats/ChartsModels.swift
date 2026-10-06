import SwiftUI
import Charts

// Example charts for comparing groups, relationships, and advanced models (Units 4–10).

/// A labeled point used by several charts.
private struct XY: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    var group: String = ""
}

// MARK: - Paired before/after lines

struct PairedLinesChart: View {
    private static let people: [(before: Double, after: Double)] = {
        var rng = SeededGenerator(seed: 61)
        return (0..<20).map { _ in
            let before = rng.normal(60, 8)
            return (before, before + rng.normal(5, 4))
        }
    }()
    private static let meanBefore = Stats.mean(people.map(\.before))
    private static let meanAfter = Stats.mean(people.map(\.after))

    var body: some View {
        Chart {
            ForEach(Self.people.indices, id: \.self) { i in
                LineMark(x: .value("Time", "Before"), y: .value("Score", Self.people[i].before), series: .value("Person", i))
                    .foregroundStyle(ChartPalette.muted.opacity(0.7))
                LineMark(x: .value("Time", "After"), y: .value("Score", Self.people[i].after), series: .value("Person", i))
                    .foregroundStyle(ChartPalette.muted.opacity(0.7))
                PointMark(x: .value("Time", "Before"), y: .value("Score", Self.people[i].before))
                    .foregroundStyle(ChartPalette.muted).symbolSize(16)
                PointMark(x: .value("Time", "After"), y: .value("Score", Self.people[i].after))
                    .foregroundStyle(ChartPalette.muted).symbolSize(16)
            }
            LineMark(x: .value("Time", "Before"), y: .value("Score", Self.meanBefore), series: .value("Person", "Mean"))
                .foregroundStyle(Theme.accent).lineStyle(StrokeStyle(lineWidth: 4))
            LineMark(x: .value("Time", "After"), y: .value("Score", Self.meanAfter), series: .value("Person", "Mean"))
                .foregroundStyle(Theme.accent).lineStyle(StrokeStyle(lineWidth: 4))
                .annotation(position: .trailing) {
                    Text("Mean change +\(Self.meanAfter - Self.meanBefore, specifier: "%.1f")")
                        .font(.caption.weight(.semibold)).foregroundStyle(Theme.accent)
                }
        }
        .chartYAxisLabel("Score")
        .statChartAxes()
        .frame(height: 260)
    }
}

// MARK: - Group means with raw points and 95% CIs

struct GroupMeansChart: View {
    private struct Group: Identifiable {
        let id: Int
        let name: String
        let values: [Double]
        let jitter: [Double]
        var mean: Double { Stats.mean(values) }
        var halfCI: Double { 2.02 * Stats.sd(values) / Double(values.count).squareRoot() }
    }

    private static let groups: [Group] = {
        var rng = SeededGenerator(seed: 71)
        return [("Lecture", 64.0), ("Active", 69.0), ("Flipped", 65.5)].enumerated().map { i, spec in
            let values = (0..<40).map { _ in rng.normal(spec.1, 9) }
            return Group(id: i, name: spec.0, values: values, jitter: values.map { _ in rng.uniform() * 0.4 - 0.2 })
        }
    }()

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.groups) { group in
                let x = Double(group.id)
                ForEach(group.values.indices, id: \.self) { i in
                    PointMark(x: .value("Method", x + group.jitter[i]), y: .value("Score", group.values[i]))
                        .foregroundStyle(ChartPalette.series[group.id].opacity(0.45))
                        .symbolSize(16)
                }
                RuleMark(x: .value("Method", x), yStart: .value("Low", group.mean - group.halfCI), yEnd: .value("High", group.mean + group.halfCI))
                    .foregroundStyle(Theme.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                PointMark(x: .value("Method", x), y: .value("Score", group.mean))
                    .foregroundStyle(Theme.textPrimary)
                    .symbolSize(70)
            }
            if let x = selectedX, let group = Self.groups.min(by: { abs(Double($0.id) - x) < abs(Double($1.id) - x) }) {
                RuleMark(x: .value("Selected", Double(group.id))).foregroundStyle(.clear)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [group.name, String(format: "M = %.1f", group.mean),
                                             String(format: "95%% CI [%.1f, %.1f]", group.mean - group.halfCI, group.mean + group.halfCI)])
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
        .chartYAxisLabel("Post-test score")
        .frame(height: 260)
    }
}

// MARK: - 2 × 2 interaction plot

struct InteractionMeansChart: View {
    private struct Cell: Identifiable {
        let id = UUID()
        let structure: String
        let distance: String
        let mean: Double
        let half: Double
    }

    private static let cells: [Cell] = [
        Cell(structure: "Simple", distance: "Short", mean: 4.5, half: 0.18),
        Cell(structure: "Simple", distance: "Long", mean: 4.1, half: 0.18),
        Cell(structure: "Complex", distance: "Short", mean: 3.6, half: 0.18),
        Cell(structure: "Complex", distance: "Long", mean: 2.5, half: 0.18),
    ]

    var body: some View {
        Chart {
            ForEach(Self.cells) { cell in
                LineMark(x: .value("Distance", cell.distance), y: .value("Mean rating", cell.mean))
                    .foregroundStyle(by: .value("Structure", cell.structure))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                RuleMark(x: .value("Distance", cell.distance), yStart: .value("Low", cell.mean - cell.half), yEnd: .value("High", cell.mean + cell.half))
                    .foregroundStyle(by: .value("Structure", cell.structure))
                PointMark(x: .value("Distance", cell.distance), y: .value("Mean rating", cell.mean))
                    .foregroundStyle(by: .value("Structure", cell.structure))
                    .symbolSize(60)
                    .annotation(position: .trailing) {
                        if cell.distance == "Long" {
                            Text(cell.structure).font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                        }
                    }
            }
        }
        .chartForegroundStyleScale(["Simple": ChartPalette.sky, "Complex": ChartPalette.orange])
        .chartLegend(.hidden)
        .chartYScale(domain: 1...7)
        .chartYAxisLabel("Mean acceptability (1–7)")
        .chartXAxisLabel("Distance")
        .statChartAxes()
        .frame(height: 250)
    }
}

// MARK: - ANCOVA: parallel lines

struct AncovaLinesChart: View {
    private static let methods = ["Lecture", "Active", "Flipped"]
    private static let effects = [0.0, 6.0, 2.5]   // exaggerated slightly so all three lines are visible

    private static let points: [XY] = {
        var rng = SeededGenerator(seed: 81)
        var out: [XY] = []
        for (i, name) in methods.enumerated() {
            for _ in 0..<40 {
                let pre = rng.normal(65, 10)
                out.append(XY(x: pre, y: 65 + 0.7 * (pre - 65) + effects[i] + rng.normal(0, 7), group: name))
            }
        }
        return out
    }()

    /// Common (pooled within-group) slope and each group's intercept.
    private static let fit: (slope: Double, intercepts: [String: Double]) = {
        var sxy = 0.0, sxx = 0.0
        var means: [String: (Double, Double)] = [:]
        for name in methods {
            let g = points.filter { $0.group == name }
            let mx = Stats.mean(g.map(\.x)), my = Stats.mean(g.map(\.y))
            means[name] = (mx, my)
            for p in g { sxy += (p.x - mx) * (p.y - my); sxx += (p.x - mx) * (p.x - mx) }
        }
        let slope = sxy / sxx
        return (slope, means.mapValues { $0.1 - slope * $0.0 })
    }()

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.points) { p in
                PointMark(x: .value("Pre-test", p.x), y: .value("Post-test", p.y))
                    .foregroundStyle(by: .value("Method", p.group))
                    .opacity(0.45)
                    .symbolSize(16)
            }
            ForEach(Self.methods, id: \.self) { name in
                let b0 = Self.fit.intercepts[name] ?? 0
                ForEach([35.0, 95.0], id: \.self) { x in
                    LineMark(x: .value("Pre-test", x), y: .value("Post-test", b0 + Self.fit.slope * x), series: .value("Line", name))
                        .foregroundStyle(by: .value("Method", name))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
            }
            if let x = selectedX {
                RuleMark(x: .value("Selected", x))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [String(format: "Pre-test %.0f → predicted post-test", x)] + Self.methods.map { name in
                            String(format: "%@: %.1f", name, (Self.fit.intercepts[name] ?? 0) + Self.fit.slope * x)
                        })
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartForegroundStyleScale(["Lecture": ChartPalette.muted, "Active": ChartPalette.sky, "Flipped": ChartPalette.orange])
        .chartLegend(position: .top, alignment: .leading)
        .chartXScale(domain: 35...95)
        .chartYScale(domain: 30...100)
        .chartXAxisLabel("Pre-test score")
        .chartYAxisLabel("Post-test score")
        .statChartAxes()
        .frame(height: 280)
    }
}

// MARK: - Chi-square: shares by group

struct ContingencyBarsChart: View {
    private struct Share: Identifiable {
        let id = UUID()
        let group: String
        let outcome: String
        let share: Double
        let count: Int
    }

    private static let groups: [(String, Int, Int)] = [("Working class", 42, 78), ("Middle class", 88, 72), ("Upper class", 61, 24)]
    private static let overall: Double = {
        let yes = groups.map(\.1).reduce(0, +), total = groups.map { $0.1 + $0.2 }.reduce(0, +)
        return Double(yes) / Double(total)
    }()
    private static let shares: [Share] = groups.flatMap { name, yes, no -> [Share] in
        let total = Double(yes + no)
        return [Share(group: name, outcome: "Attended", share: Double(yes) / total, count: yes),
                Share(group: name, outcome: "Did not attend", share: Double(no) / total, count: no)]
    } + [Share(group: "If independent", outcome: "Attended", share: overall, count: 0),
         Share(group: "If independent", outcome: "Did not attend", share: 1 - overall, count: 0)]

    var body: some View {
        Chart(Self.shares) { s in
            BarMark(x: .value("Group", s.group), y: .value("Share", s.share), width: .ratio(0.6))
                .foregroundStyle(by: .value("Outcome", s.outcome))
                .opacity(s.group == "If independent" ? 0.55 : 1)
                .annotation(position: .overlay) {
                    if s.outcome == "Attended" {
                        Text("\(Int((s.share * 100).rounded()))%").font(.caption.weight(.semibold)).foregroundStyle(Theme.onAccent)
                    }
                }
        }
        .chartForegroundStyleScale(["Attended": ChartPalette.sky, "Did not attend": Theme.hairline])
        .chartLegend(position: .top, alignment: .leading)
        .chartYAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1]) { value in
                AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v * 100))%").foregroundStyle(Theme.textSecondary) } }
            }
        }
        .chartXAxis {
            AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) }
        }
        .frame(height: 250)
    }
}

// MARK: - Correlation gallery

struct CorrelationGalleryChart: View {
    private struct Panel: Identifiable {
        let id: Int
        let title: String
        let points: [XY]
    }

    private static let panels: [Panel] = {
        var rng = SeededGenerator(seed: 91)
        func linear(_ rho: Double) -> [XY] {
            let xs = (0..<70).map { _ in rng.normal() }
            var noise = (0..<70).map { _ in rng.normal() }
            // Remove the noise's chance correlation with x so each panel shows its intended r.
            let fit = Stats.fitLine(xs, noise)
            noise = zip(xs, noise).map { $1 - (fit.intercept + fit.slope * $0) }
            let sdNoise = Stats.sd(noise), sdX = Stats.sd(xs)
            return zip(xs, noise).map { x, e in
                XY(x: x, y: rho * x / sdX + (1 - rho * rho).squareRoot() * e / sdNoise)
            }
        }
        let curved = (0..<70).map { _ -> XY in
            let x = rng.uniform() * 4 - 2
            return XY(x: x, y: x * x + rng.normal(0, 0.3))
        }
        return [linear(-0.8), linear(0), linear(0.5), curved].enumerated().map { i, pts in
            var r = Stats.correlation(pts.map(\.x), pts.map(\.y))
            if abs(r) < 0.005 { r = 0 }   // avoid printing "−0.00"
            let label = i == 3 ? String(format: "r = %.2f — but strongly curved", r) : String(format: "r = %.2f", r)
            return Panel(id: i, title: label, points: pts)
        }
    }()

    var body: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                panel(Self.panels[0])
                panel(Self.panels[1])
            }
            GridRow {
                panel(Self.panels[2])
                panel(Self.panels[3])
            }
        }
    }

    private func panel(_ panel: Panel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(panel.title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Chart(panel.points) { p in
                PointMark(x: .value("X", p.x), y: .value("Y", p.y))
                    .foregroundStyle(panel.id == 3 ? ChartPalette.orange : ChartPalette.sky)
                    .symbolSize(14)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 130)
            .padding(8)
            .background(Theme.background.opacity(0.5), in: .rect(cornerRadius: 8))
        }
    }
}

// MARK: - Between- vs. within-person

struct BetweenWithinChart: View {
    private struct Person: Identifiable {
        let id: Int
        let usual: Double
        let days: [XY]
        var meanWellbeing: Double { Stats.mean(days.map(\.y)) }
    }

    private static let people: [Person] = {
        var rng = SeededGenerator(seed: 101)
        return (0..<8).map { p in
            let usual = 5 + Double(p) * 0.6 + rng.normal(0, 0.2)
            let baseline = 4 + 0.45 * (usual - 7) + rng.normal(0, 0.15)
            let days = (0..<14).map { _ -> XY in
                let hours = usual + rng.normal(0, 1.1)
                return XY(x: hours, y: baseline - 0.35 * (hours - usual) + rng.normal(0, 0.25))
            }
            return Person(id: p, usual: usual, days: days)
        }
    }()
    private static let betweenFit = Stats.fitLine(people.map(\.usual), people.map(\.meanWellbeing))

    var body: some View {
        Chart {
            ForEach(Self.people) { person in
                ForEach(person.days) { day in
                    PointMark(x: .value("Work hours", day.x), y: .value("Wellbeing", day.y))
                        .foregroundStyle(by: .value("Layer", "One person's days"))
                        .symbolSize(10)
                        .opacity(0.6)
                }
                let fit = Stats.fitLine(person.days.map(\.x), person.days.map(\.y))
                let xs = person.days.map(\.x)
                ForEach([xs.min() ?? 0, xs.max() ?? 0], id: \.self) { x in
                    LineMark(x: .value("Work hours", x), y: .value("Wellbeing", fit.intercept + fit.slope * x), series: .value("Person", "p\(person.id)"))
                        .foregroundStyle(by: .value("Layer", "Within-person slope"))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                PointMark(x: .value("Work hours", person.usual), y: .value("Wellbeing", person.meanWellbeing))
                    .foregroundStyle(by: .value("Layer", "Person averages (between)"))
                    .symbolSize(60)
            }
            ForEach([4.5, 10.0], id: \.self) { x in
                LineMark(x: .value("Work hours", x), y: .value("Wellbeing", Self.betweenFit.intercept + Self.betweenFit.slope * x), series: .value("Person", "between"))
                    .foregroundStyle(by: .value("Layer", "Person averages (between)"))
                    .lineStyle(StrokeStyle(lineWidth: 3, dash: [6, 3]))
            }
        }
        .chartForegroundStyleScale([
            "One person's days": ChartPalette.muted,
            "Within-person slope": ChartPalette.sky,
            "Person averages (between)": ChartPalette.orange,
        ])
        .chartLegend(position: .top, alignment: .leading)
        .chartXScale(domain: 1...12)
        .chartYScale(domain: 1.5...7)
        .chartXAxisLabel("Daily work hours")
        .chartYAxisLabel("Daily wellbeing")
        .statChartAxes()
        .frame(height: 290)
    }
}

// MARK: - Regression line with residuals

struct RegressionResidualsChart: View {
    private static let points: [XY] = {
        var rng = SeededGenerator(seed: 111)
        return (0..<22).map { _ in
            let x = 1 + rng.uniform() * 6
            return XY(x: x, y: 1.5 + 0.55 * x + rng.normal(0, 0.6))
        }
    }()
    private static let fit = Stats.fitLine(points.map(\.x), points.map(\.y))

    @State private var selectedX: Double?

    private var selected: XY? {
        guard let x = selectedX else { return nil }
        return Self.points.min { abs($0.x - x) < abs($1.x - x) }
    }

    var body: some View {
        Chart {
            ForEach(Self.points) { p in
                RuleMark(x: .value("Rumination", p.x),
                         yStart: .value("Predicted", Self.fit.intercept + Self.fit.slope * p.x),
                         yEnd: .value("Observed", p.y))
                    .foregroundStyle(ChartPalette.pink.opacity(selected?.id == p.id ? 1 : 0.6))
                    .lineStyle(StrokeStyle(lineWidth: selected?.id == p.id ? 2.5 : 1.2))
            }
            ForEach([1.0, 7.0], id: \.self) { x in
                LineMark(x: .value("Rumination", x), y: .value("Anxiety", Self.fit.intercept + Self.fit.slope * x))
                    .foregroundStyle(ChartPalette.sky)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            ForEach(Self.points) { p in
                PointMark(x: .value("Rumination", p.x), y: .value("Anxiety", p.y))
                    .foregroundStyle(Theme.textPrimary)
                    .symbolSize(selected?.id == p.id ? 60 : 28)
            }
            if let p = selected {
                let predicted = Self.fit.intercept + Self.fit.slope * p.x
                PointMark(x: .value("Rumination", p.x), y: .value("Anxiety", p.y)).symbolSize(1).foregroundStyle(Color.clear)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [String(format: "Observed %.2f", p.y), String(format: "Predicted %.2f", predicted),
                                             String(format: "Residual %+.2f", p.y - predicted)])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXAxisLabel(String(format: "Rumination   ·   fitted line: ŷ = %.2f + %.2f·x", Self.fit.intercept, Self.fit.slope))
        .chartYAxisLabel("Anxiety")
        .statChartAxes()
        .frame(height: 270)
    }
}

// MARK: - Residual plots: healthy vs. funnel

struct ResidualPlotsChart: View {
    private static let healthy: [XY] = {
        var rng = SeededGenerator(seed: 121)
        return (0..<80).map { _ in let f = 1 + rng.uniform() * 9; return XY(x: f, y: rng.normal(0, 1)) }
    }()
    private static let funnel: [XY] = {
        var rng = SeededGenerator(seed: 122)
        return (0..<80).map { _ in let f = 1 + rng.uniform() * 9; return XY(x: f, y: rng.normal(0, 0.15 * f)) }
    }()

    var body: some View {
        HStack(spacing: 16) {
            panel("Healthy: random scatter around 0", Self.healthy, ChartPalette.sky)
            panel("Problem: spread grows (funnel)", Self.funnel, ChartPalette.orange)
        }
    }

    private func panel(_ title: String, _ points: [XY], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Chart {
                RuleMark(y: .value("Zero", 0)).foregroundStyle(Theme.textSecondary).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                ForEach(points) { p in
                    PointMark(x: .value("Fitted", p.x), y: .value("Residual", p.y)).foregroundStyle(color).symbolSize(14)
                }
            }
            .chartYScale(domain: -3.5...3.5)
            .chartXAxisLabel("Fitted value")
            .chartYAxisLabel("Residual")
            .statChartAxes()
            .frame(height: 190)
        }
    }
}

// MARK: - Coefficient plot

struct CoefficientPlotChart: View {
    private struct Coefficient: Identifiable {
        let id: String
        let estimate: Double
        let low: Double
        let high: Double
        var excludesZero: Bool { low > 0 || high < 0 }
    }

    private static let coefficients: [Coefficient] = [
        Coefficient(id: "Rumination", estimate: 0.48, low: 0.39, high: 0.57),
        Coefficient(id: "Social media use", estimate: 0.14, low: 0.04, high: 0.24),
        Coefficient(id: "Phone checking", estimate: 0.03, low: -0.07, high: 0.13),
        Coefficient(id: "Age", estimate: -0.02, low: -0.11, high: 0.07),
    ]

    @State private var selectedY: String?

    var body: some View {
        Chart {
            RuleMark(x: .value("Zero", 0))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            ForEach(Self.coefficients) { c in
                let label = c.excludesZero ? "CI excludes 0" : "CI includes 0"
                RuleMark(xStart: .value("Low", c.low), xEnd: .value("High", c.high), y: .value("Predictor", c.id))
                    .foregroundStyle(by: .value("Evidence", label))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                PointMark(x: .value("β", c.estimate), y: .value("Predictor", c.id))
                    .foregroundStyle(by: .value("Evidence", label))
                    .symbolSize(80)
                    .annotation(position: .trailing) {
                        if selectedY == c.id {
                            ChartReadout(lines: [String(format: "β = %.2f", c.estimate), String(format: "95%% CI [%.2f, %.2f]", c.low, c.high)])
                        }
                    }
            }
        }
        .chartYSelection(value: $selectedY)
        .chartForegroundStyleScale(["CI excludes 0": ChartPalette.sky, "CI includes 0": ChartPalette.muted])
        .chartLegend(position: .top, alignment: .leading)
        .chartXScale(domain: -0.3...0.7)
        .chartXAxisLabel("Standardized coefficient (β) with 95% CI — outcome: anxiety")
        .statChartAxes()
        .frame(height: 220)
    }
}

// MARK: - Logistic curve

struct LogisticCurveChart: View {
    private static let observations: [XY] = {
        var rng = SeededGenerator(seed: 131)
        return (0..<220).map { _ in
            let x = 1 + rng.uniform() * 6
            let y: Double = rng.uniform() < Stats.logistic(-6 + 1.25 * x) ? 1 : 0
            return XY(x: x, y: y + (y == 1 ? -1 : 1) * rng.uniform() * 0.05)
        }
    }()
    private static let binned: [XY] = stride(from: 1.0, to: 7.0, by: 1.0).map { low in
        let inBin = observations.filter { $0.x >= low && $0.x < low + 1 }
        let share = Double(inBin.filter { $0.y > 0.5 }.count) / Double(max(inBin.count, 1))
        return XY(x: low + 0.5, y: share)
    }

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.observations) { o in
                PointMark(x: .value("Rumination", o.x), y: .value("Outcome", o.y))
                    .foregroundStyle(by: .value("Layer", "Individual people (0 or 1)"))
                    .symbolSize(10)
                    .opacity(0.5)
            }
            ForEach(Array(stride(from: 1.0, through: 7.0, by: 0.1)), id: \.self) { x in
                LineMark(x: .value("Rumination", x), y: .value("Probability", Stats.logistic(-6 + 1.25 * x)))
                    .foregroundStyle(by: .value("Layer", "Fitted probability"))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            ForEach(Self.binned) { b in
                PointMark(x: .value("Rumination", b.x), y: .value("Probability", b.y))
                    .foregroundStyle(by: .value("Layer", "Observed share per bin"))
                    .symbolSize(70)
                    .symbol(.diamond)
            }
            if let x = selectedX {
                RuleMark(x: .value("Selected", x))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        let p = Stats.logistic(-6 + 1.25 * x)
                        ChartReadout(lines: [String(format: "Rumination %.1f", x), String(format: "P(high anxiety) = %.2f", p),
                                             String(format: "odds = %.2f", p / (1 - p))])
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartForegroundStyleScale([
            "Individual people (0 or 1)": ChartPalette.muted,
            "Fitted probability": ChartPalette.sky,
            "Observed share per bin": ChartPalette.orange,
        ])
        .chartLegend(position: .top, alignment: .leading)
        .chartYScale(domain: -0.08...1.08)
        .chartXAxisLabel("Rumination")
        .chartYAxisLabel("P(high anxiety)")
        .statChartAxes()
        .frame(height: 270)
    }
}

// MARK: - Mixed model: random intercepts and slopes

struct RandomEffectsChart: View {
    private static let people: [(intercept: Double, slope: Double)] = {
        var rng = SeededGenerator(seed: 141)
        return (0..<12).map { _ in (4 + rng.normal(0, 0.6), -0.25 + rng.normal(0, 0.12)) }
    }()

    var body: some View {
        Chart {
            ForEach(Self.people.indices, id: \.self) { i in
                ForEach([-3.0, 3.0], id: \.self) { x in
                    LineMark(x: .value("Hours vs. usual", x), y: .value("Wellbeing", Self.people[i].intercept + Self.people[i].slope * x),
                             series: .value("Person", "p\(i)"))
                        .foregroundStyle(by: .value("Layer", "Each person (random intercept + slope)"))
                        .lineStyle(StrokeStyle(lineWidth: 1.2))
                }
            }
            ForEach([-3.0, 3.0], id: \.self) { x in
                LineMark(x: .value("Hours vs. usual", x), y: .value("Wellbeing", 4 - 0.25 * x), series: .value("Person", "fixed"))
                    .foregroundStyle(by: .value("Layer", "Fixed effect (average person)"))
                    .lineStyle(StrokeStyle(lineWidth: 4))
            }
        }
        .chartForegroundStyleScale([
            "Each person (random intercept + slope)": ChartPalette.muted,
            "Fixed effect (average person)": Theme.accent,
        ])
        .chartLegend(position: .top, alignment: .leading)
        .chartXAxisLabel("Work hours relative to the person's usual (person-mean centered)")
        .chartYAxisLabel("Wellbeing")
        .statChartAxes()
        .frame(height: 260)
    }
}

// MARK: - Rater agreement table

struct AgreementTableChart: View {
    private struct Cell: Identifiable {
        let id = UUID()
        let a: Int
        let b: Int
        let count: Int
    }

    private static let cells: [Cell] = {
        var rng = SeededGenerator(seed: 151)
        var counts = Array(repeating: Array(repeating: 0, count: 6), count: 6)
        for _ in 0..<120 {
            let quality = rng.normal(3.5, 1.1)
            let a = min(max(Int((quality + rng.normal(0, 0.6)).rounded()), 1), 6)
            let b = min(max(Int((quality + 0.3 + rng.normal(0, 0.6)).rounded()), 1), 6)
            counts[a - 1][b - 1] += 1
        }
        return (1...6).flatMap { a in (1...6).map { b in Cell(a: a, b: b, count: counts[a - 1][b - 1]) } }
    }()
    private static let maxCount = cells.map(\.count).max() ?? 1

    var body: some View {
        Chart(Self.cells) { cell in
            RectangleMark(x: .value("Rater B", "\(cell.b)"), y: .value("Rater A", "\(cell.a)"), width: .ratio(0.94), height: .ratio(0.9))
                .foregroundStyle(cell.a == cell.b ? Theme.accent.opacity(0.15 + 0.85 * Double(cell.count) / Double(Self.maxCount))
                                                  : ChartPalette.sky.opacity(0.08 + 0.7 * Double(cell.count) / Double(Self.maxCount)))
                .annotation(position: .overlay) {
                    if cell.count > 0 {
                        Text("\(cell.count)").font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Double(cell.count) > 0.5 * Double(Self.maxCount) ? Theme.onAccent : Theme.textPrimary)
                    }
                }
        }
        .chartXAxisLabel("Rater B's score", position: .top)
        .chartYAxisLabel("Rater A's score", position: .leading)
        .chartXAxis { AxisMarks(position: .top) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
        .chartYScale(domain: ["6", "5", "4", "3", "2", "1"])
        .frame(height: 280)
    }
}

// MARK: - Simple slopes

struct SimpleSlopesChart: View {
    private static let levels: [(String, Double)] = [("Low mindfulness (−1 SD)", -1), ("Average", 0), ("High mindfulness (+1 SD)", 1)]

    private static func predicted(_ x: Double, _ w: Double) -> Double { 4 + (0.5 - 0.2 * w) * x - 0.2 * w }
    private static func se(_ x: Double) -> Double { 0.07 * (1 + x * x / 3).squareRoot() }

    @State private var selectedX: Double?

    var body: some View {
        Chart {
            ForEach(Self.levels, id: \.0) { label, w in
                ForEach(Array(stride(from: -2.5, through: 2.5, by: 0.25)), id: \.self) { x in
                    AreaMark(x: .value("Social media (centered)", x),
                             yStart: .value("Low", Self.predicted(x, w) - 1.96 * Self.se(x)),
                             yEnd: .value("High", Self.predicted(x, w) + 1.96 * Self.se(x)),
                             series: .value("Band", label))
                        .foregroundStyle(by: .value("Mindfulness", label))
                        .opacity(0.18)
                    LineMark(x: .value("Social media (centered)", x), y: .value("Rumination", Self.predicted(x, w)), series: .value("Line", label))
                        .foregroundStyle(by: .value("Mindfulness", label))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
            }
            if let x = selectedX {
                RuleMark(x: .value("Selected", x))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartReadout(lines: [String(format: "Social media %+.1f from average", x)] + Self.levels.map { label, w in
                            String(format: "%@: %.2f", label, Self.predicted(x, w))
                        })
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartForegroundStyleScale([
            "Low mindfulness (−1 SD)": ChartPalette.orange,
            "Average": ChartPalette.muted,
            "High mindfulness (+1 SD)": ChartPalette.sky,
        ])
        .chartLegend(position: .top, alignment: .leading)
        .chartXScale(domain: -2.5...2.5)
        .chartYScale(domain: 2...6.5)
        .chartXAxisLabel("Social media use (centered)")
        .chartYAxisLabel("Predicted rumination")
        .statChartAxes()
        .frame(height: 270)
    }
}

// MARK: - Ordinal response shares

struct OrdinalSharesChart: View {
    private struct Share: Identifiable {
        let id = UUID()
        let condition: String
        let rating: String
        let share: Double
    }

    private static let thresholds = [-2.5, -1.6, -0.8, 0.0, 0.8, 1.6]
    private static let conditions: [(String, Double)] = [
        ("Simple / short", 0.6), ("Simple / long", 0.1), ("Complex / short", -0.2), ("Complex / long", -1.3),
    ]
    private static let shares: [Share] = conditions.flatMap { name, eta -> [Share] in
        let cumulative = thresholds.map { Stats.logistic(($0 - eta) / 0.9) } + [1]
        return (0..<7).map { k in
            let lower = k == 0 ? 0 : cumulative[k - 1]
            return Share(condition: name, rating: "\(k + 1)", share: cumulative[k] - lower)
        }
    }

    @State private var selectedY: String?

    var body: some View {
        Chart(Self.shares) { s in
            BarMark(x: .value("Share", s.share), y: .value("Condition", s.condition), height: .ratio(0.65))
                .foregroundStyle(by: .value("Rating", s.rating))
        }
        .chartForegroundStyleScale(domain: ["1", "2", "3", "4", "5", "6", "7"],
                                   range: [Color(hex: 0xEF6F6C), Color(hex: 0xF4A582), Color(hex: 0xFDDBC7), Color(hex: 0x94A3B8),
                                           Color(hex: 0xD1E5F0), Color(hex: 0x92C5DE), Color(hex: 0x56B4E9)])
        .chartYSelection(value: $selectedY)
        .chartOverlay { _ in
            if let condition = selectedY {
                let high = Self.shares.filter { $0.condition == condition && Int($0.rating)! >= 5 }.map(\.share).reduce(0, +)
                ChartReadout(lines: [condition, String(format: "Rated 5–7: %.0f%%", 100 * high)])
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .allowsHitTesting(false)
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        .chartXAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1]) { value in
                AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v * 100))%").foregroundStyle(Theme.textSecondary) } }
            }
        }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
        .frame(height: 220)
    }
}

// MARK: - Transition heatmap

struct TransitionHeatmapChart: View {
    private struct Cell: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let share: Double
    }

    private static let modes = ["Car", "Bus", "Bike", "Walk"]
    private static let matrix: [[Double]] = [
        [0.71, 0.17, 0.07, 0.05],
        [0.10, 0.78, 0.08, 0.04],
        [0.08, 0.15, 0.70, 0.07],
        [0.09, 0.17, 0.09, 0.65],
    ]
    private static let cells: [Cell] = modes.indices.flatMap { i in
        modes.indices.map { j in Cell(from: modes[i], to: modes[j], share: matrix[i][j]) }
    }

    var body: some View {
        Chart(Self.cells) { cell in
            RectangleMark(x: .value("Next week", cell.to), y: .value("This week", cell.from), width: .ratio(0.94), height: .ratio(0.9))
                .foregroundStyle(ChartPalette.sky.opacity(0.08 + 0.92 * cell.share))
                .annotation(position: .overlay) {
                    Text(String(format: "%.2f", cell.share))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(cell.share > 0.4 ? Theme.onAccent : Theme.textPrimary)
                }
        }
        .chartXAxisLabel("Mode next week", position: .top)
        .chartYAxisLabel("Mode this week", position: .leading)
        .chartXAxis { AxisMarks(position: .top) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
        .chartYScale(domain: Self.modes)
        .chartXScale(domain: Self.modes)
        .frame(height: 240)
    }
}

// MARK: - LCA class profiles

struct ClassProfilesChart: View {
    private static let items = ["Reread", "Notes", "Self-test", "Spaced", "Explain", "Peers"]
    private static let classes: [(String, [Double])] = [
        ("Passive review (45%)", [0.90, 0.85, 0.15, 0.10, 0.10, 0.20]),
        ("Active practice (35%)", [0.50, 0.50, 0.85, 0.75, 0.60, 0.25]),
        ("Social learning (20%)", [0.40, 0.40, 0.40, 0.30, 0.80, 0.90]),
    ]

    var body: some View {
        Chart {
            ForEach(Self.classes, id: \.0) { name, probabilities in
                ForEach(Self.items.indices, id: \.self) { i in
                    LineMark(x: .value("Strategy", Self.items[i]), y: .value("P(yes)", probabilities[i]))
                        .foregroundStyle(by: .value("Class", name))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Strategy", Self.items[i]), y: .value("P(yes)", probabilities[i]))
                        .foregroundStyle(by: .value("Class", name))
                        .symbolSize(40)
                }
            }
        }
        .chartForegroundStyleScale(domain: Self.classes.map(\.0), range: ChartPalette.series)
        .chartLegend(position: .top, alignment: .leading)
        .chartYScale(domain: 0...1)
        .chartYAxisLabel("Probability of using the strategy")
        .statChartAxes()
        .frame(height: 260)
    }
}

// MARK: - LPA profile means

struct ProfileMeansChart: View {
    private static let indicators = ["Wellbeing", "Stress", "Support", "Sleep"]
    private static let profiles: [(String, [Double])] = [
        ("Thriving (50%)", [5.5, 2.5, 5.5, 5.0]),
        ("Average (30%)", [4.0, 4.0, 4.0, 4.0]),
        ("Struggling (20%)", [2.5, 5.5, 3.0, 2.8]),
    ]

    var body: some View {
        Chart {
            ForEach(Self.profiles, id: \.0) { name, means in
                ForEach(Self.indicators.indices, id: \.self) { i in
                    LineMark(x: .value("Indicator", Self.indicators[i]), y: .value("Mean", means[i]))
                        .foregroundStyle(by: .value("Profile", name))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Indicator", Self.indicators[i]), y: .value("Mean", means[i]))
                        .foregroundStyle(by: .value("Profile", name))
                        .symbolSize(40)
                }
            }
        }
        .chartForegroundStyleScale(domain: Self.profiles.map(\.0), range: [ChartPalette.sky, ChartPalette.muted, ChartPalette.orange])
        .chartLegend(position: .top, alignment: .leading)
        .chartYScale(domain: 1...7)
        .chartYAxisLabel("Profile mean (1–7)")
        .statChartAxes()
        .frame(height: 250)
    }
}
