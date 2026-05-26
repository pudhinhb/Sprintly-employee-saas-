import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

import '../helpers/common_colors.dart';
import '../helpers/common_strings.dart';
import 'common_widgets.dart';


class CustomLoaderButton extends HookWidget {
  final String? buttonText;
  final Color? buttonTextColor;
  final double? buttonTextSize;
  final Color? buttonColor;
  final Future<void> Function() onTap;
  final Color? loaderColor;
  final double? height;
  final double? width;
  final Duration? seconds;
  final bool? isIconButton;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final double? borderRadius;
  final Color? borderColor;
  final TextAlign? buttonTextAlign;


  const CustomLoaderButton({
    super.key,
    required this.buttonText,
    required this.buttonTextColor,
    required this.buttonColor,
    required this.buttonTextSize,
    required this.onTap,
    required this.loaderColor,
    this.height,
    this.width,
    this.seconds,
    this.isIconButton = false,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.borderRadius,
    this.buttonTextAlign,
    this.borderColor
  });

  @override
  Widget build(BuildContext context) {
    var isLoading = useState(false);

    return SizedBox(
      height: height ?? 5.h,
      width: width ?? 15.w,
      child: MaterialButton(
        elevation: 0.0,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor ?? Colors.transparent),
            borderRadius: BorderRadius.circular(borderRadius ?? 5.0)
        ),
        onPressed: () async {
          if(isLoading.value){
            showWarning(text:  'Please wait..., another action is in progress.');
            return;
          }
          try{
            isLoading.value = true;
            seconds != null ?
            await Future.delayed(seconds!) :
            await Future.delayed(Duration(seconds: 1));
            await onTap();
            isLoading.value = false;
          } catch(e){
            logger.e('error in loader button: $e');
          } finally{
            isLoading.value = false;
          }
        },
        color: buttonColor,
        child: isLoading.value ? Center(
          child: LoadingAnimationWidget.threeRotatingDots(
            color: loaderColor ?? Theme.of(context).colorScheme.onPrimary,
            size: height != null ? (height! - 10) : 3.h,
          ),
        ) : isIconButton != null && isIconButton! ? Icon(icon, color: iconColor, size: iconSize ?? 15.0,) :
        customTextWithClip(
          text: buttonText ?? '',
          fontWeight: FontWeight.bold,
          textColor: buttonTextColor ?? Theme.of(context).colorScheme.onPrimary,
          fontSize: buttonTextSize ?? 15.0,
          textAlign: buttonTextAlign ?? TextAlign.center,
        ),
      ),
    );
  }
}
