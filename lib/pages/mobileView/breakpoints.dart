import 'package:flutter/material.dart';

class Breakpoints {
  // Screen Breakpoints
  static const double mobileSmall = 320;
  static const double mobileLarge = 480;
  static const double tabletSmall = 600;
  static const double tabletLarge = 768;
  static const double tabletXLarge = 988;

  // General helpers
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletSmall;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletSmall &&
      MediaQuery.of(context).size.width <= tabletXLarge;
}

// Typography for different screen sizes
class ResponsiveTypography {
  // Mobile Small (320px - 479px)
  static const mobileSmall = TypographyConfig(
    heading: 24,
    subHeading: 15,
    normal: 12.5,
    medium: 16,
    large: 20,
  );

  // Mobile Large (480px - 599px)
  static const mobileLarge = TypographyConfig(
    heading: 28,
    subHeading: 16,
    normal: 13,
    medium: 17,
    large: 22,
  );

  // Tablet Small (600px - 767px)
  static const tabletSmall = TypographyConfig(
    heading: 32,
    subHeading: 16,
    normal: 14,
    medium: 18,
    large: 26,
  );

  // Tablet Large (768px+)
  static const tabletLarge = TypographyConfig(
    heading: 36,
    subHeading: 26,
    normal: 15,
    medium: 20,
    large: 28,
  );

  // Get appropriate typography based on screen width
  static TypographyConfig getTypography(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < Breakpoints.mobileLarge) {
      return mobileSmall;
    } else if (width < Breakpoints.tabletSmall) {
      return mobileLarge;
    } else if (width < Breakpoints.tabletLarge) {
      return tabletSmall;
    } else {
      return tabletLarge;
    }
  }
}

class TypographyConfig {
  final double heading;
  final double subHeading;
  final double normal;
  final double medium;
  final double large;

  const TypographyConfig({
    required this.heading,
    required this.subHeading,
    required this.normal,
    required this.medium,
    required this.large,
  });
}

// Spacing configuration for different screen sizes
class ResponsiveSpacing {
  // Mobile Small (320px - 479px)
  static const mobileSmall = SpacingConfig(
    paddingSmall: 8,
    paddingMedium: 12,
    paddingLarge: 16,
    marginSmall: 8,
    marginMedium: 12,
    marginLarge: 16,
    spacingSmall: 4,
    spacingMedium: 8,
    spacingLarge: 12,
  );

  // Mobile Large (480px - 599px)
  static const mobileLarge = SpacingConfig(
    paddingSmall: 10,
    paddingMedium: 14,
    paddingLarge: 20,
    marginSmall: 10,
    marginMedium: 14,
    marginLarge: 20,
    spacingSmall: 6,
    spacingMedium: 10,
    spacingLarge: 14,
  );

  // Tablet Small (600px - 767px)
  static const tabletSmall = SpacingConfig(
    paddingSmall: 12,
    paddingMedium: 18,
    paddingLarge: 24,
    marginSmall: 12,
    marginMedium: 18,
    marginLarge: 24,
    spacingSmall: 8,
    spacingMedium: 12,
    spacingLarge: 16,
  );

  // Tablet Large (768px+)
  static const tabletLarge = SpacingConfig(
    paddingSmall: 14,
    paddingMedium: 20,
    paddingLarge: 28,
    marginSmall: 14,
    marginMedium: 20,
    marginLarge: 28,
    spacingSmall: 10,
    spacingMedium: 14,
    spacingLarge: 20,
  );

  // Get appropriate spacing based on screen width
  static SpacingConfig getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < Breakpoints.mobileLarge) {
      return mobileSmall;
    } else if (width < Breakpoints.tabletSmall) {
      return mobileLarge;
    } else if (width < Breakpoints.tabletLarge) {
      return tabletSmall;
    } else {
      return tabletLarge;
    }
  }
}

class SpacingConfig {
  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;
  final double marginSmall;
  final double marginMedium;
  final double marginLarge;
  final double spacingSmall;
  final double spacingMedium;
  final double spacingLarge;

  const SpacingConfig({
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.marginSmall,
    required this.marginMedium,
    required this.marginLarge,
    required this.spacingSmall,
    required this.spacingMedium,
    required this.spacingLarge,
  });
}

// Responsive utility widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, TypographyConfig, SpacingConfig) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final typography = ResponsiveTypography.getTypography(context);
        final spacing = ResponsiveSpacing.getSpacing(context);
        return builder(context, typography, spacing);
      },
    );
  }
}

// Example usage widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextType type;
  final TextAlign? textAlign;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveText({
    Key? key,
    required this.text,
    this.type = TextType.normal,
    this.textAlign,
    this.color,
    this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.getTypography(context);

    double fontSize;
    switch (type) {
      case TextType.heading:
        fontSize = typography.heading;
        break;
      case TextType.subHeading:
        fontSize = typography.subHeading;
        break;
      case TextType.normal:
        fontSize = typography.normal;
        break;
      case TextType.medium:
        fontSize = typography.medium;
        break;
      case TextType.large:
        fontSize = typography.large;
        break;
    }

    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}

enum TextType { heading, subHeading, normal, medium, large }

// Example responsive container with dynamic spacing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final SpacingType paddingType;
  final SpacingType? marginType;
  final Color? color;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.paddingType = SpacingType.medium,
    this.marginType,
    this.color,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveSpacing.getSpacing(context);

    double padding;
    switch (paddingType) {
      case SpacingType.small:
        padding = spacing.paddingSmall;
        break;
      case SpacingType.medium:
        padding = spacing.paddingMedium;
        break;
      case SpacingType.large:
        padding = spacing.paddingLarge;
        break;
    }

    EdgeInsets? margin;
    if (marginType != null) {
      double marginValue;
      switch (marginType!) {
        case SpacingType.small:
          marginValue = spacing.marginSmall;
          break;
        case SpacingType.medium:
          marginValue = spacing.marginMedium;
          break;
        case SpacingType.large:
          marginValue = spacing.marginLarge;
          break;
      }
      margin = EdgeInsets.all(marginValue);
    }

    return Container(
      padding: EdgeInsets.all(padding),
      margin: margin,
      color: decoration == null ? color : null,
      decoration: decoration,
      child: child,
    );
  }
}

enum SpacingType { small, medium, large }

// Responsive SizedBox for spacing
class ResponsiveGap extends StatelessWidget {
  final SpacingType type;
  final bool horizontal;

  const ResponsiveGap({
    Key? key,
    this.type = SpacingType.medium,
    this.horizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveSpacing.getSpacing(context);

    double size;
    switch (type) {
      case SpacingType.small:
        size = spacing.spacingSmall;
        break;
      case SpacingType.medium:
        size = spacing.spacingMedium;
        break;
      case SpacingType.large:
        size = spacing.spacingLarge;
        break;
    }

    return SizedBox(
      width: horizontal ? size : null,
      height: horizontal ? null : size,
    );
  }
}
