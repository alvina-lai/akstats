import SwiftUI

// Previews for checking the example charts.
private struct ChartPair: View {
    let kinds: [ChartKind]

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            ForEach(kinds.indices, id: \.self) { i in
                ChartKindView(kind: kinds[i])
                    .padding(16)
                    .background(Theme.surface, in: .rect(cornerRadius: 12))
                    .frame(width: 520)
            }
        }
        .padding(20)
        .background(Theme.background)
        .foregroundStyle(Theme.textPrimary, Theme.textSecondary)
        .preferredColorScheme(.dark)
    }
}

#Preview("Charts 1") { ChartPair(kinds: [.skewedDistribution, .normalCurve]) }
#Preview("Charts 2") { ChartPair(kinds: [.ancovaLines, .betweenWithin]) }
#Preview("Charts 3") { ChartPair(kinds: [.correlationGallery, .agreementTable]) }
#Preview("Charts 4") { ChartPair(kinds: [.ordinalShares, .logisticCurve]) }
#Preview("Charts 5") { ChartPair(kinds: [.confidenceIntervals, .boxplotComparison]) }
#Preview("Charts 6") { ChartPair(kinds: [.simpleSlopes, .coefficientPlot]) }
