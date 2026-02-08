import 'package:flutter/material.dart';

class Responsive {
  // breakponts : for screen layout (colums, show/hide widgets, switching layouts)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  // screen size : calculating percentages and postitoning
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // text
  static double text(
    BuildContext context, {
    required double size,
  }) {
    return width(context) / 375 * size;
  }

  // icon size
  static double icon(
    BuildContext context, {
    required double size,
  }) {
    return width(context) / 375 * size;
  }

  // radius
  static double radius(
    BuildContext context, {
    required double size,
  }) {
    return width(context) / 375 * size;
  }
}