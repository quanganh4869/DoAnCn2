import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            "Subtotal",
            "\$36.36",
            ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            "Shipping",
            "\$3.6",
            ),
            const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            "Tax",
            "\$0.36",
            ), 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
           _buildSummaryRow(
            context,
            "STotal",
            "\$40.32",
            isTotal: true
            ), 
        ],
      ),
    );
  }
  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}){
    final textStyle = isTotal ? AppTextStyles.h3 : AppTextStyles.bodyLarge;
    final color = isTotal
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge!.color!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.withColor(textStyle, color),
            ),
            Text(
              value,
              style: AppTextStyles.withColor(textStyle, color),
            )
          ],
        );
  }
}
