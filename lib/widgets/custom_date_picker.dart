import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../helpers/common_strings.dart';
import '../helpers/common_colors.dart';
import 'common_widgets.dart';

/*
  Author: Sanjay Prasath G
  Date: 04th August 2025
 */
class CustomDatePicker extends HookWidget{
  final TextEditingController controller;
  final TextInputType textInputType;
  final String? title;
  final bool? isReadOnly;
  final String? hintText;
  final int? maxLines;
  final String? Function(String?)? validator;

  const CustomDatePicker({
    required this.controller,
    required this.textInputType,
    required this.validator,
    this.title,
    this.hintText,
    this.maxLines,
    this.isReadOnly,
    super.key
  });

  @override
  Widget build(BuildContext context) {

    Future pickDate() async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 5)),
        builder: (context, child) {
          return Theme(
            data: ThemeData(
              primaryColor: CommonColors.primary,
              colorScheme: ColorScheme.light(
                primary: CommonColors.primary,
                onPrimary: CommonColors.white,
                onSurface: CommonColors.black,
              ),
              dialogBackgroundColor: CommonColors.white,
              fontFamily: primaryFontFamily,
              textTheme: TextTheme(
                bodyMedium: TextStyle(
                  fontFamily: primaryFontFamily,
                  color: CommonColors.black,
                ),
                labelLarge: TextStyle(
                  fontFamily: primaryFontFamily,
                  color: CommonColors.primary,
                ),
                titleLarge: TextStyle(
                  fontFamily: primaryFontFamily,
                  color: CommonColors.black,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        controller.text = pickedDate.toString().split(' ')[0];
      }
    }

    return TextFormField(
      onTap: () async{
        await pickDate();
      },
      controller: controller,
      keyboardType: textInputType,
      maxLines: maxLines ?? 1,
      readOnly: isReadOnly ?? false,
      cursorColor: CommonColors.primary,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        color: CommonColors.black,
        fontFamily: primaryFontFamily
      ),
      decoration: InputDecoration(
        suffixIcon: Icon(Icons.calendar_today, color: CommonColors.primary),
        label: customTextWithClip(
            text: title ?? '',
            textColor: CommonColors.black,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.start
        ),
        hintText: hintText ?? '',
        hintStyle: TextStyle(
            color: CommonColors.grey,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            fontFamily: primaryFontFamily
        ),
        errorStyle: TextStyle(
            color: CommonColors.red,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            fontFamily: primaryFontFamily
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: CommonColors.black, width: 0.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: CommonColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: CommonColors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: CommonColors.grey),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: CommonColors.red, width: 1.5),
        ),
      ),
    );
  }
}