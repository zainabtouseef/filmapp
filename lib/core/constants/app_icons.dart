import 'package:flutter/material.dart';

/// Centralized IconData used by dashboard chrome (categories, bottom
/// nav, badges). Add new icons here rather than inlining `Icons.x`
/// deep inside a screen, so the icon language stays consistent and
/// easy to audit.
class AppIcons {
  AppIcons._();

  // ---- Discover categories -----------------------------------------------
  static const actors = Icons.person_outline_rounded;
  static const models = Icons.people_outline_rounded;
  static const directors = Icons.shield_outlined;
  static const makeupArtists = Icons.person_outline_rounded;
  static const more = Icons.grid_view_rounded;

  // ---- Search / filters ---------------------------------------------------
  static const search = Icons.search_rounded;
  static const tune = Icons.tune_rounded;
  static const location = Icons.location_on_outlined;
  static const chevronDown = Icons.keyboard_arrow_down_rounded;
  static const chevronRight = Icons.chevron_right_rounded;

  // ---- Talent card ----------------------------------------------------
  static const star = Icons.star_rounded;
  static const verifiedUser = Icons.verified_user_outlined;
  static const negotiable = Icons.sell_outlined;
  static const respondsFast = Icons.bolt_rounded;
  static const bookmark = Icons.bookmark_border_rounded;
  static const sendBooking = Icons.near_me_outlined;
  static const play = Icons.play_arrow_rounded;
  static const check = Icons.check_rounded;

  // ---- Trust row ----------------------------------------------------------
  static const escrow = Icons.shield_outlined;
  static const contract = Icons.description_outlined;
  static const securePayments = Icons.lock_outline_rounded;
  static const superAdminVerified = Icons.verified_outlined;

  // ---- Bottom nav -----------------------------------------------------------
  static const home = Icons.home_outlined;
  static const discover = Icons.search_rounded;
  static const create = Icons.add_rounded;
  static const bookings = Icons.work_outline_rounded;
  static const profile = Icons.person_outline_rounded;

  // ---- Misc -----------------------------------------------------------------
  static const notifications = Icons.notifications_none_rounded;
  static const castingCall = Icons.movie_creation_outlined;
  static const themeSun = Icons.wb_sunny_outlined;
  static const themeMoon = Icons.dark_mode_outlined;
}
