// The blog's colours over zulip-flutter's design variables, for light and dark.
// patches/0001-brand-colour.patch calls this from zulipThemeData(); everything else
// keeps upstream's values.
//
// Blog colours: light teal #149791 (text #0F7D78); dark: background #111, text #aeaeae,
// teal #2c9e94.
import 'dart:ui';

import '../widgets/theme.dart';
import 'config.g.dart';

const _lightTeal = kIphoneblogBrandColor;
const _lightTealText = Color(0xff0f7d78);
const _darkTeal = Color(0xff2c9e94);
const _darkTealPressed = Color(0xff1f7a72);
const _darkBackground = Color(0xff111111);
const _darkText = Color(0xffaeaeae);

/// Seed for Material's colour scheme, per brightness.
Color iphoneblogSeedColor(Brightness brightness) =>
  brightness == Brightness.dark ? _darkTeal : _lightTeal;

DesignVariables iphoneblogDesignVariables(DesignVariables v, Brightness brightness) {
  switch (brightness) {
    case Brightness.light:
      return v.copyWith(
        icon: _lightTeal,
        groupIcon: _lightTeal,
        radioFillSelected: _lightTeal,
        link: _lightTealText,
        fabBg: _lightTeal,
        fabBgPressed: _lightTealText,
        fabShadow: _lightTealText.withValues(alpha: 0.4),
        contextMenuItemBg: _lightTeal,
        contextMenuItemIcon: _lightTeal,
        contextMenuItemText: _lightTealText,
        btnBgAttHighIntInfoNormal: _lightTeal,
        btnBgAttHighIntInfoActive: _lightTealText,
        btnBgAttMediumIntInfoNormal: _lightTeal.withValues(alpha: 0.12),
        btnBgAttMediumIntInfoActive: _lightTeal.withValues(alpha: 0.22),
        btnBgAttLowIntInfoActive: _lightTealText.withValues(alpha: 0.09),
        btnLabelAttLowIntInfo: _lightTealText,
        btnLabelAttMediumIntInfo: _lightTealText,
      );
    case Brightness.dark:
      return v.copyWith(
        mainBackground: _darkBackground,
        bgMessageRegular: _darkBackground,
        textMessage: _darkText,
        icon: _darkTeal,
        groupIcon: _darkTeal,
        radioFillSelected: _darkTeal,
        link: _darkTeal,
        fabBg: _darkTeal,
        fabBgPressed: _darkTealPressed,
        contextMenuItemBg: _darkTeal,
        contextMenuItemIcon: _darkTeal,
        contextMenuItemText: _darkTeal,
        btnBgAttHighIntInfoNormal: _darkTealPressed,
        btnBgAttHighIntInfoActive: _darkTealPressed,
        btnBgAttMediumIntInfoNormal: _darkTeal.withValues(alpha: 0.12),
        btnBgAttMediumIntInfoActive: _darkTeal.withValues(alpha: 0.22),
        btnBgAttLowIntInfoActive: _darkTeal.withValues(alpha: 0.17),
        btnLabelAttLowIntInfo: _darkTeal,
        btnLabelAttMediumIntInfo: _darkTeal,
      );
  }
}
