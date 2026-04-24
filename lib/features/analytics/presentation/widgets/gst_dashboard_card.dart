import 'package:flutter/material.dart';
import '../../../../features/billing/data/bill_model.dart';
import '../../../../core/widgets/clay_widgets.dart';

/// GST Analytics Dashboard Card
///
/// Shows Output Tax (collected on sales), Available ITC (paid on purchases),
/// and Net GST Payable to Government.
class GstDashboardCard extends StatelessWidget {
  final List<BillModel> salesBills; // Bills where partyType == 'customer'
  final List<BillModel> purchaseBills; // Bills where partyType == 'supplier'

  const GstDashboardCard({
    super.key,
    required this.salesBills,
    required this.purchaseBills,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = kClayBaseColor;

    // Output Tax = Total GST collected on sales
    double outputTax = 0;
    for (final bill in salesBills) {
      outputTax += bill.totalCgst + bill.totalSgst + bill.totalIgst;
    }

    // ITC = Total GST paid on purchases from suppliers
    double inputTaxCredit = 0;
    for (final bill in purchaseBills) {
      inputTaxCredit += bill.totalCgst + bill.totalSgst + bill.totalIgst;
    }

    final netPayable = outputTax - inputTaxCredit;

    return ClayContainer(
      color: baseColor,
      borderRadius: 20,
      depth: 12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.deepOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GST Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      "Tax collected vs ITC",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Three metric tiles
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: "Output Tax",
                    subtitle: "On Sales",
                    value: outputTax,
                    color: Colors.orange,
                    icon: Icons.arrow_upward,
                    baseColor: baseColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: "ITC Available",
                    subtitle: "On Purchases",
                    value: inputTaxCredit,
                    color: Colors.blue,
                    icon: Icons.arrow_downward,
                    baseColor: baseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Net Payable — full width
            ClayContainer(
              color: baseColor,
              borderRadius: 14,
              depth: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: netPayable > 0
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        netPayable > 0
                            ? Icons.payment
                            : Icons.check_circle_outline,
                        color: netPayable > 0 ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Net GST Payable",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            netPayable > 0
                                ? "Balance due to Govt."
                                : netPayable < 0
                                ? "Verified ITC excess"
                                : "No liability",
                            style: TextStyle(
                              fontSize: 11,
                              color: netPayable > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${netPayable.abs().toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: netPayable > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String subtitle,
    required double value,
    required Color color,
    required IconData icon,
    required Color baseColor,
  }) {
    return ClayContainer(
      color: baseColor,
      borderRadius: 14,
      depth: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "₹${value.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
