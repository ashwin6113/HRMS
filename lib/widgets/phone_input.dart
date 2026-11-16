import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';

class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodePicked,
    this.showLabel = false,
    this.isDisabled = false,
    this.needDarkTheme = false,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String countryCode;
  final Function(String code) onCountryCodePicked;
  final bool showLabel;
  final bool needDarkTheme;
  final bool isDisabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  Future<void> _pickCountryCode(BuildContext context) async {
    showCountryPicker(context: context, showPhoneCode: true, onSelect: (Country country) => onCountryCodePicked.call('+${country.phoneCode}'));
  }

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final color = Theme.of(context).colorScheme;

    final Widget child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: "Mobile Number",
            controller: widget.controller,
            validator: (v) => v == null || v.isEmpty ? "Enter Mobile Number" : null,
            isMandatory: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: widget.isDisabled ? null : () => widget._pickCountryCode(context),
                  highlightColor: Colors.transparent,
                  splashColor: Colors.white.withAlpha(25),
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Text(
                      "+${widget.countryCode.replaceAll('+', '')}",
                      style: TextStyle(color: color.onSurface, fontSize: 16.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(widget.errorText!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MOBILE NUMBER',
                  style: TextStyle(color: widget.needDarkTheme ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text('*', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          child,
        ],
      );
    }
    return child;
  }
}
