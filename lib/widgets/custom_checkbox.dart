import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final String label;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const CustomCheckbox({
    super.key,
    required this.label,
    this.initialValue = false,
    required this.onChanged,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.initialValue;
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث حالة الـ checkbox عند تغير القيمة الأولية من الخارج
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        isChecked = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value ?? false;
            });
            widget.onChanged(isChecked);
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                isChecked = !isChecked;
              });
              widget.onChanged(isChecked);
            },
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
