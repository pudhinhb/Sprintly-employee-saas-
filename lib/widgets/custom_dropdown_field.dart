import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_validator/form_validator.dart';
import 'package:sizer/sizer.dart';

import '../../helpers/common_colors.dart';
import '../helpers/common_strings.dart';
import 'common_widgets.dart';

class CustomDropdownField extends HookWidget{
  final String title;
  final double? titleSize;
  final String? hintText;
  final List<String> itemsList;
  final String? initiallySelectedItem;
  final bool? isReadOnly;
  final bool? isRequired;
  final Function(String?)? onChanged;

  const CustomDropdownField({
    super.key,
      required this.title,
      required this.itemsList,
      required this.isRequired,
      required this.onChanged,
      this.titleSize,
      this.hintText,
      this.initiallySelectedItem, 
      this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {

    var selectedItem = useState<String?>(initiallySelectedItem != null && initiallySelectedItem!.isNotEmpty ? initiallySelectedItem : null);

    logger.i(itemsList);

    return Column(
      children: [
        Row(
          children: [
            customTextWithClip(
                text: title,
                textColor: CommonColors.black,
                fontSize: titleSize ?? 13.0,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.start
            ),
            Visibility(
                child: Column(
                  children: [
                    customTextWithClip(
                        text: "*",
                        textColor: CommonColors.red,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.start
                    ),
                  ],
                )
            )
          ],
        ),
        0.5.h.hGap,
        DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              hint: customTextWithClip(
                  text: hintText ?? '',
                  textColor: CommonColors.grey,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.start,
              ),
                // padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
                borderRadius: BorderRadius.circular(15.0),
                autovalidateMode: isRequired != null && isRequired! ? AutovalidateMode.onUserInteraction : null,
              value: itemsList.contains(selectedItem.value)
                  ? selectedItem.value
                  : null,
                items: itemsList.map((String item){
                  return DropdownMenuItem<String>(
                    value: item,
                    child: SizedBox(
                      width: 35.w,
                      child: customTextWithClip(
                            text: item,
                            textColor: CommonColors.black,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            textAlign: TextAlign.start,
                        ),
                    ),
                  );
                }).toList(),
              onChanged: isReadOnly != null && isReadOnly!
                  ? null
                  : (newValue) {
                selectedItem.value = newValue ?? '';
                if (onChanged != null) {
                  onChanged!(newValue);
                }
              },
              dropdownColor: CommonColors.white,
              validator: isRequired != null && isRequired! ?
                ValidationBuilder(requiredMessage: 'Please select $title field.').build() : null,
              decoration: InputDecoration(
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
            )
        )
      ],
    );
  }
  
}