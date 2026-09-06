import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';

/// One labelled field on S-25.
///
/// The border tells the whole story: hairline at rest, grape while focused,
/// raspberry once a validation error has been *earned* — which only happens
/// after the field is left, never mid-typing.
class ProfileField extends StatefulWidget {
  const ProfileField({
    required this.label,
    required this.controller,
    required this.onBlur,
    super.key,
    this.error,
    this.trailing,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;

  /// Fired when focus leaves, which is what arms the error.
  final VoidCallback onBlur;

  final String? error;

  /// The live availability result on the username field.
  final Widget? trailing;

  final TextInputType? keyboardType;

  /// The bible's field height.
  static const double height = 50;

  @override
  State<ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<ProfileField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (!hasFocus && _isFocused) widget.onBlur();
    setState(() => _isFocused = hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: textTheme.labelSmall),
        SizedBox(height: 6.h),
        Container(
          height: ProfileField.height.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: quizoo.s1,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: hasError
                  ? quizoo.bad
                  : _isFocused
                  ? quizoo.g
                  : quizoo.ln,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  cursorColor: quizoo.g,
                  style: textTheme.bodyLarge!.copyWith(color: quizoo.tx),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                SizedBox(width: AppSpacing.sm.w),
                widget.trailing!,
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 5.h),
            child: Text(
              widget.error!,
              style: textTheme.bodyMedium!.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: quizoo.bad,
              ),
            ),
          ),
      ],
    );
  }
}

/// A read-only field that cycles through a fixed list on tap.
///
/// Mocked deliberately: a real country picker is a searchable sheet over a
/// full ISO list, which is data work rather than design work (plan 002's
/// S-25 note).
class ProfilePickerField extends StatelessWidget {
  const ProfilePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: ProfileField.height.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: quizoo.s1,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: quizoo.ln, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: textTheme.bodyLarge!.copyWith(color: quizoo.tx),
                  ),
                ),
                Text(
                  '▾',
                  style: textTheme.bodyLarge!.copyWith(color: quizoo.tx3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
