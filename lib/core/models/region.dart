class MusicRegion {
  final String code;
  final String name;
  final String emoji;
  final String saavnLanguage;
  final String youtubeQuery;
  final String lastfmCountry;

  const MusicRegion({
    required this.code,
    required this.name,
    required this.emoji,
    required this.saavnLanguage,
    required this.youtubeQuery,
    required this.lastfmCountry,
  });

  static const List<MusicRegion> all = [
    MusicRegion(code: 'IN', name: 'India', emoji: '🇮🇳', saavnLanguage: 'hindi', youtubeQuery: 'top hindi hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_TA', name: 'Tamil Nadu', emoji: '🇮🇳', saavnLanguage: 'tamil', youtubeQuery: 'top tamil hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_TE', name: 'Telangana / AP', emoji: '🇮🇳', saavnLanguage: 'telugu', youtubeQuery: 'top telugu hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_KN', name: 'Karnataka', emoji: '🇮🇳', saavnLanguage: 'kannada', youtubeQuery: 'top kannada hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_ML', name: 'Kerala', emoji: '🇮🇳', saavnLanguage: 'malayalam', youtubeQuery: 'top malayalam hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_PB', name: 'Punjab', emoji: '🇮🇳', saavnLanguage: 'punjabi', youtubeQuery: 'top punjabi hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'IN_BN', name: 'West Bengal', emoji: '🇮🇳', saavnLanguage: 'bengali', youtubeQuery: 'top bengali hit song', lastfmCountry: 'India'),
    MusicRegion(code: 'US', name: 'United States', emoji: '🇺🇸', saavnLanguage: 'english', youtubeQuery: 'top pop hit song USA', lastfmCountry: 'United States'),
    MusicRegion(code: 'GB', name: 'United Kingdom', emoji: '🇬🇧', saavnLanguage: 'english', youtubeQuery: 'top UK hit song', lastfmCountry: 'United Kingdom'),
    MusicRegion(code: 'CA', name: 'Canada', emoji: '🇨🇦', saavnLanguage: 'english', youtubeQuery: 'top canadian hit song', lastfmCountry: 'Canada'),
    MusicRegion(code: 'AU', name: 'Australia', emoji: '🇦🇺', saavnLanguage: 'english', youtubeQuery: 'top australian hit song', lastfmCountry: 'Australia'),
    MusicRegion(code: 'PK', name: 'Pakistan', emoji: '🇵🇰', saavnLanguage: 'hindi', youtubeQuery: 'top urdu hit song', lastfmCountry: 'Pakistan'),
    MusicRegion(code: 'BD', name: 'Bangladesh', emoji: '🇧🇩', saavnLanguage: 'bengali', youtubeQuery: 'top bangla hit song', lastfmCountry: 'Bangladesh'),
    MusicRegion(code: 'LK', name: 'Sri Lanka', emoji: '🇱🇰', saavnLanguage: 'tamil', youtubeQuery: 'top sinhala hit song', lastfmCountry: 'Sri Lanka'),
    MusicRegion(code: 'NP', name: 'Nepal', emoji: '🇳🇵', saavnLanguage: 'hindi', youtubeQuery: 'top nepali hit song', lastfmCountry: 'Nepal'),
    MusicRegion(code: 'AE', name: 'UAE', emoji: '🇦🇪', saavnLanguage: 'hindi', youtubeQuery: 'top arabic hit song', lastfmCountry: 'United Arab Emirates'),
    MusicRegion(code: 'SA', name: 'Saudi Arabia', emoji: '🇸🇦', saavnLanguage: 'hindi', youtubeQuery: 'top saudi arabic hit song', lastfmCountry: 'Saudi Arabia'),
    MusicRegion(code: 'DE', name: 'Germany', emoji: '🇩🇪', saavnLanguage: 'english', youtubeQuery: 'top german hit song', lastfmCountry: 'Germany'),
    MusicRegion(code: 'FR', name: 'France', emoji: '🇫🇷', saavnLanguage: 'english', youtubeQuery: 'top french hit song', lastfmCountry: 'France'),
    MusicRegion(code: 'ES', name: 'Spain', emoji: '🇪🇸', saavnLanguage: 'english', youtubeQuery: 'top spanish hit song', lastfmCountry: 'Spain'),
    MusicRegion(code: 'MX', name: 'Mexico', emoji: '🇲🇽', saavnLanguage: 'english', youtubeQuery: 'top mexican hit song', lastfmCountry: 'Mexico'),
    MusicRegion(code: 'BR', name: 'Brazil', emoji: '🇧🇷', saavnLanguage: 'english', youtubeQuery: 'top brazil hit song', lastfmCountry: 'Brazil'),
    MusicRegion(code: 'AR', name: 'Argentina', emoji: '🇦🇷', saavnLanguage: 'english', youtubeQuery: 'top argentina hit song', lastfmCountry: 'Argentina'),
    MusicRegion(code: 'JP', name: 'Japan', emoji: '🇯🇵', saavnLanguage: 'english', youtubeQuery: 'top jpop hit song', lastfmCountry: 'Japan'),
    MusicRegion(code: 'KR', name: 'South Korea', emoji: '🇰🇷', saavnLanguage: 'english', youtubeQuery: 'top kpop hit song', lastfmCountry: 'South Korea'),
    MusicRegion(code: 'NG', name: 'Nigeria', emoji: '🇳🇬', saavnLanguage: 'english', youtubeQuery: 'top afrobeats hit song', lastfmCountry: 'Nigeria'),
    MusicRegion(code: 'GH', name: 'Ghana', emoji: '🇬🇭', saavnLanguage: 'english', youtubeQuery: 'top ghana hit song', lastfmCountry: 'Ghana'),
    MusicRegion(code: 'ZA', name: 'South Africa', emoji: '🇿🇦', saavnLanguage: 'english', youtubeQuery: 'top south africa hit song', lastfmCountry: 'South Africa'),
    MusicRegion(code: 'TR', name: 'Turkey', emoji: '🇹🇷', saavnLanguage: 'english', youtubeQuery: 'top turkish hit song', lastfmCountry: 'Turkey'),
    MusicRegion(code: 'ID', name: 'Indonesia', emoji: '🇮🇩', saavnLanguage: 'english', youtubeQuery: 'top indonesia hit song', lastfmCountry: 'Indonesia'),
    MusicRegion(code: 'PH', name: 'Philippines', emoji: '🇵🇭', saavnLanguage: 'english', youtubeQuery: 'top opm hit song', lastfmCountry: 'Philippines'),
    MusicRegion(code: 'MY', name: 'Malaysia', emoji: '🇲🇾', saavnLanguage: 'english', youtubeQuery: 'top malaysia hit song', lastfmCountry: 'Malaysia'),
    MusicRegion(code: 'SG', name: 'Singapore', emoji: '🇸🇬', saavnLanguage: 'english', youtubeQuery: 'top singapore hit song', lastfmCountry: 'Singapore'),
    MusicRegion(code: 'IT', name: 'Italy', emoji: '🇮🇹', saavnLanguage: 'english', youtubeQuery: 'top italian hit song', lastfmCountry: 'Italy'),
    MusicRegion(code: 'RU', name: 'Russia', emoji: '🇷🇺', saavnLanguage: 'english', youtubeQuery: 'top russian hit song', lastfmCountry: 'Russian Federation'),
  ];

  static MusicRegion fromCode(String code) {
    return all.firstWhere(
      (r) => r.code == code,
      orElse: () => all.first,
    );
  }

  static MusicRegion fromLocale(String localeCountryCode) {
    final upper = localeCountryCode.toUpperCase();
    return all.firstWhere(
      (r) => r.code == upper,
      orElse: () => fromCode('IN'),
    );
  }
}
