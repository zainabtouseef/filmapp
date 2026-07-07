# CineConnect — Flutter

Dark cinematic film-industry marketplace UI, matching the reference design.

## Run

```bash
flutter create .      # generates android/ ios/ etc. if you don't have them
flutter pub get
flutter run
```

The app runs immediately — missing portrait photos fall back to a
cinematic placeholder, so nothing crashes before you add assets.

## Project structure

```
lib/
  main.dart                        app entry + MaterialApp(theme: AppTheme.dark)
  theme/
    app_colors.dart                near-black bg, metallic gold, ivory text, gradients
    app_text_styles.dart           Playfair (serif headings) + Inter (UI)
    app_theme.dart                 ThemeData + glassCard() / chip() decorations
  models/
    talent.dart                    Talent model, sample data, PortraitImage widget
  widgets/
    chips.dart                     CategoryChip, FilterControl, GoldSwitch, TagChip
    featured_talent_card.dart      the big featured card (portrait, price, trust, CTAs)
    talent_carousel_card.dart      small portrait card for the carousel
    cine_bottom_nav.dart           floating nav w/ elevated center Create button
  screens/
    dashboard_screen.dart          the full dashboard, wiring everything together
```

## Fonts (optional, for exact match)

Download **Playfair Display** and **Inter** from Google Fonts, drop the
`.ttf` files into `assets/fonts/`, then uncomment the `fonts:` block in
`pubspec.yaml`. Without them the app uses the platform default sans —
still fully functional.

## Real photos

Add JPGs to `assets/images/` using the names referenced in
`lib/models/talent.dart` (`sana_khalid.jpg`, `danish.jpg`, `hira.jpg`,
`bilal.jpg`, `ayeza.jpg`, plus `me.jpg` for the header avatar).

## Design system

All colors/typography live in `lib/theme/`. Change the gold, background
tone, or fonts once there and it propagates across every screen. Reuse
`AppTheme.glassCard()` and `AppTheme.chip()` for new surfaces so future
screens stay consistent with the dashboard.
```
