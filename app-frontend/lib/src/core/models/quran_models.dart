class QuranLanguage {
  final String id;
  final String name;
  final String code;

  const QuranLanguage(
      {required this.id, required this.name, required this.code});

  factory QuranLanguage.fromJson(Map<String, dynamic> json) {
    return QuranLanguage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class QuranReciter {
  final String id;
  final String name;
  final String? imageUrl;

  const QuranReciter({required this.id, required this.name, this.imageUrl});

  factory QuranReciter.fromJson(Map<String, dynamic> json) {
    return QuranReciter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

class QuranSurah {
  final int id;
  final String name;
  final int juzId;

  const QuranSurah({required this.id, required this.name, required this.juzId});

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      juzId: json['juzId'] is int
          ? json['juzId']
          : int.parse(json['juzId'].toString()),
    );
  }
}

class QuranJuz {
  final int id;
  final String name;
  final List<QuranSurah> surahs;

  const QuranJuz({required this.id, required this.name, required this.surahs});

  factory QuranJuz.fromJson(Map<String, dynamic> json) {
    var surahList = json['surahs'] as List? ?? [];
    List<QuranSurah> parsedSurahs =
        surahList.map((i) => QuranSurah.fromJson(i)).toList();
    return QuranJuz(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      surahs: parsedSurahs,
    );
  }
}

class QuranRecitation {
  final String id;
  final String title;
  final String subtitle; // 1. Added Subtitle
  final String audioUrl;
  final int surahId;

  const QuranRecitation({
    required this.id,
    required this.title,
    required this.subtitle, // 2. Added to constructor
    required this.audioUrl,
    required this.surahId,
  });

  factory QuranRecitation.fromJson(Map<String, dynamic> json) {
    return QuranRecitation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '', // 3. Parse Subtitle
      audioUrl: json['audioUrl'] ?? '',
      surahId: json['surahId'] is int
          ? json['surahId']
          : int.parse(json['surahId'].toString()),
    );
  }
}

// --- CONTENT ITEM MODEL ---
class QuranContentItem {
  final QuranSurah surah;
  final List<QuranRecitation> recitations;

  QuranContentItem({required this.surah, required this.recitations});

  factory QuranContentItem.fromJson(Map<String, dynamic> json) {
    var list = json['recitations'] as List? ?? [];
    List<QuranRecitation> recs =
        list.map((i) => QuranRecitation.fromJson(i)).toList();

    return QuranContentItem(
      surah: QuranSurah.fromJson(json['surah']),
      recitations: recs,
    );
  }
}
