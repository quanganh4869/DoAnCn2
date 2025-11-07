import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({super.key});

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
                  offset: const Offset(0, 2)
            ),
            ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  "assets/images/MasterCard.png",
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Visa ending in 3636",
                      style: AppTextStyles.withColor(
                        AppTextStyles.h3,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expires 12/24",
                      style: AppTextStyles.withColor(
                        AppTextStyles.h3,
                        isDark ? Colors.grey[400]! : Colors.grey[600]!,
                      ),
                    )
                  ],
                ),
              ),
              IconButton(
                onPressed: (){},
                 icon: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).primaryColor,
                 )
                 )
            ],
          )
        ],
      ),
    );
  }
}
