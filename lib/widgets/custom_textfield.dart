import 'package:flutter/material.dart';
import '../helpers/common_colors.dart';
import '../helpers/common_strings.dart';

import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String hintText;
  final bool showIcon;
  final bool showPsw;
  final TextInputType textInputType;
  final bool readOnly;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;
  final bool? isRequired;
  final List<TextInputFormatter>? inputFormatters;
  final ValueSetter<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const CustomTextField({
    required this.controller,
    required this.title,
    required this.showIcon,
    required this.showPsw,
    required this.textInputType,
    required this.readOnly,
    required this.validator,
    required this.hintText,
    required this.isRequired,
    super.key,
    this.maxLength,
    this.maxLines,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    showPassword = widget.showPsw;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: TextFormField(
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: widget.controller,
        keyboardType: widget.textInputType,
        obscureText: showPassword,
        readOnly: widget.readOnly,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        textInputAction: widget.textInputAction,
        cursorColor: Theme.of(context).colorScheme.primary,
        maxLines: widget.maxLines,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: primaryFontFamily,
              fontSize: 14,
            ),
        decoration: InputDecoration(
          errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: primaryFontFamily,
                color: Theme.of(context).colorScheme.error,
              ),
          fillColor: Theme.of(context).colorScheme.surface,
          label: Text(
            '${widget.title} ${widget.isRequired == true ? '*' : ''}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: primaryFontFamily,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          focusColor: Theme.of(context).colorScheme.primary,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText:
              '${widget.hintText} ${widget.isRequired == true ? '*' : ''}',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: primaryFontFamily,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          suffixIcon: widget.showIcon
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  icon: !showPassword
                      ? Icon(
                          Icons.visibility_off_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      : Icon(
                          Icons.visibility_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                )
              : null,
        ),
      ),
    );
  }
}
