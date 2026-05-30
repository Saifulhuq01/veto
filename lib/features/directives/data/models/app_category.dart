/// App category definitions used for group-level blocking.
enum AppCategory {
  social('Social Media', 'com.social'),
  games('Games', 'com.games'),
  entertainment('Entertainment', 'com.entertainment'),
  productivity('Productivity', 'com.productivity'),
  communication('Communication', 'com.communication'),
  other('Other', 'com.other');

  const AppCategory(this.label, this.prefix);
  final String label;
  final String prefix;

  /// Map from Android ApplicationInfo category constants.
  static AppCategory fromAndroidCategory(int? category) {
    switch (category) {
      case 0: // CATEGORY_GAME
        return AppCategory.games;
      case 1: // CATEGORY_AUDIO
      case 2: // CATEGORY_VIDEO
      case 4: // CATEGORY_IMAGE
        return AppCategory.entertainment;
      case 3: // CATEGORY_SOCIAL
        return AppCategory.social;
      case 5: // CATEGORY_NEWS
      case 6: // CATEGORY_MAPS
      case 7: // CATEGORY_PRODUCTIVITY
        return AppCategory.productivity;
      default:
        return AppCategory.other;
    }
  }

  /// Manually classify well-known packages.
  static AppCategory classifyPackage(String packageName) {
    final socialPackages = {
      'com.instagram.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.snapchat.android',
      'com.reddit.frontpage',
      'com.linkedin.android',
      'com.pinterest',
      'com.tumblr',
      'com.discord',
    };
    final entertainmentPackages = {
      'com.google.android.youtube',
      'com.netflix.mediaclient',
      'com.spotify.music',
      'com.zhiliaoapp.musically', // TikTok
      'com.amazon.avod.thirdpartyclient',
      'tv.twitch.android.app',
    };
    final communicationPackages = {
      'com.whatsapp',
      'org.telegram.messenger',
      'com.Slack',
      'com.google.android.apps.messaging',
    };

    if (socialPackages.contains(packageName)) return AppCategory.social;
    if (entertainmentPackages.contains(packageName)) {
      return AppCategory.entertainment;
    }
    if (communicationPackages.contains(packageName)) {
      return AppCategory.communication;
    }
    return AppCategory.other;
  }
}
