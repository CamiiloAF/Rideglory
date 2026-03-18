import 'package:flutter/widgets.dart';

extension WidgetPaddingExtension on Widget {
  // Padding
  Widget horizontalPadding(double value) => Padding(
        padding: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  Widget verticalPadding(double value) => Padding(
        padding: EdgeInsets.symmetric(vertical: value),
        child: this,
      );

  Widget symmetricPadding({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget allPadding(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  Widget paddingLTRB(double left, double top, double right, double bottom) =>
      Padding(
        padding: EdgeInsets.fromLTRB(left, top, right, bottom),
        child: this,
      );

  // Margin
  Widget horizontalMargin(double value) => Container(
        margin: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  Widget verticalMargin(double value) => Container(
        margin: EdgeInsets.symmetric(vertical: value),
        child: this,
      );

  Widget allMargin(double value) => Container(
        margin: EdgeInsets.all(value),
        child: this,
      );

  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Container(
        margin: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  Widget marginLTRB(double left, double top, double right, double bottom) =>
      Container(
        margin: EdgeInsets.fromLTRB(left, top, right, bottom),
        child: this,
      );
}

// Named helper: keep API discoverability consistent with the rest of the DS.
extension WidgetAppSizePaddingExtension on Widget {
  Widget horizontalPaddingSize(double value) => horizontalPadding(value);

  Widget verticalPaddingSize(double value) => verticalPadding(value);

  Widget allPaddingSize(double value) => allPadding(value);
}

