import 'package:flutter/material.dart';

const kPrimary = Color(0xFF00C8D7);

/// 玻璃卡片容器
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.07),
        ),
      ),
      child: child,
    );
  }
}

/// 分区标题（带可选启用开关）
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool? enabled;
  final ValueChanged<bool>? onEnabledChanged;
  final String activeText;
  final String inactiveText;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.enabled,
    this.onEnabledChanged,
    this.activeText = '启用',
    this.inactiveText = '关闭',
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ],
          ),
        ),
        if (enabled != null && onEnabledChanged != null) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(value: enabled!, onChanged: onEnabledChanged, activeColor: kPrimary),
              Text(enabled! ? activeText : inactiveText,
                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }
}

/// 开关字段（标签 + 开关 + active/inactive 文案）
class SwitchField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String activeText;
  final String inactiveText;

  const SwitchField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeText = '开启',
    this.inactiveText = '关闭',
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: onSurface, fontSize: 14))),
          Text(value ? activeText : inactiveText,
              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12)),
          const SizedBox(width: 6),
          Switch(value: value, onChanged: onChanged, activeColor: kPrimary),
        ],
      ),
    );
  }
}

/// 文本输入字段
class TextFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool number;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChangedSync;

  const TextFieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.number = false,
    this.enabled = true,
    this.maxLines = 1,
    this.onChangedSync,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: obscure,
            enabled: enabled,
            maxLines: obscure ? 1 : maxLines,
            keyboardType: number ? TextInputType.number : TextInputType.text,
            onChanged: onChangedSync,
            style: TextStyle(color: onSurface, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 下拉选择字段
class SelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // 保证 value 在 items 中，否则用第一项避免崩溃
    final values = items.map((e) => e.value).toList();
    final safeValue = values.contains(value) ? value : (items.isNotEmpty ? items.first.value : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: onSurface.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: safeValue,
                isExpanded: true,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                style: TextStyle(color: onSurface, fontSize: 14),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 数字步进字段
class NumberField extends StatelessWidget {
  final String label;
  final num value;
  final num min;
  final num max;
  final num step;
  final ValueChanged<num> onChanged;

  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99999,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: onSurface, fontSize: 14))),
          _stepBtn(context, Icons.remove, () {
            final v = (value - step).clamp(min, max);
            onChanged(v);
          }),
          Container(
            width: 56,
            alignment: Alignment.center,
            child: Text('$value', style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          _stepBtn(context, Icons.add, () {
            final v = (value + step).clamp(min, max);
            onChanged(v);
          }),
        ],
      ),
    );
  }

  Widget _stepBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: kPrimary),
      ),
    );
  }
}

/// 滑块字段（0-1 置信度等）
class SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const SliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions = 100,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final v = value.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: onSurface, fontSize: 14))),
              Text(v.toStringAsFixed(2), style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: v,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: kPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 复选框（带边框）
class CheckboxChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CheckboxChip({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? kPrimary.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? kPrimary : onSurface.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18, color: value ? kPrimary : onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: onSurface, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
