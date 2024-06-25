import 'package:flutter/material.dart';
import 'package:infinity_messenger/core/constants.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.padding = 15,
    required this.text,
    this.fontSize = 18,
    this.width = double.infinity,
    this.icon,
    this.onTap,
    this.valueForChange,
    this.textColor,
    this.buttonColor,
  });

  final double? width;
  final double? padding;
  final String text;
  final double? fontSize;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool? valueForChange;
  final Color? textColor;
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: valueForChange != null
          ? valueForChange == true
              ? buttonColor ?? Theme.of(context).colorScheme.onBackground
              : buttonColor != null
                  ? buttonColor!.withOpacity(0.5)
                  : Theme.of(context).colorScheme.onBackground.withOpacity(0.5)
          : buttonColor ?? Theme.of(context).colorScheme.onBackground,
      surfaceTintColor: Theme.of(context).colorScheme.background,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          width: width,
          padding: EdgeInsets.all(padding!),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon != null
                  ? Row(
                      children: [
                        Icon(icon),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              Text(
                text,
                style: myButtonTextStyle(context, fontSize!,textColor, 'bold', 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
