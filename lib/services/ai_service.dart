import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';

// ---------------------------------------------------------------------------
// Markdown temizleyici ve Dil Düzeltici
// ---------------------------------------------------------------------------
/// Model yabancı dil (İngilizce/Rusça) sızdırırsa anında Türkçeleştirir.
String _sanitizeTurkishOnly(String text) {
  if (text.isEmpty) return text;
  var s = text;
  final latinToTr = <RegExp, String>{
    // İngilizce sızıntıları
    RegExp(r'\b[Ss]PF\s*[0-9]+\b'): 'yüksek güneş koruyuculu ürün',
    RegExp(r'\b[Hh][Yy]aluronic\b'): 'hiluronik asit',
    RegExp(r'\b[Nn]iacinamide\b'): 'niasinamid',
    RegExp(r'\bmorning\s+routine\b', caseSensitive: false): 'sabah rutini',
    RegExp(r'\b[Dd]aily\s+routine\b', caseSensitive: false): 'günlük rutin',
    RegExp(r'\b[Nn]aturally\b'): 'doğal biçimde',
    RegExp(r'\b[Hh]ydrating\b'): 'nemlendirici',
    RegExp(r'\b[Hh]ydration\b'): 'nemlendirme',
    RegExp(r'\bmoisturisers?\b', caseSensitive: false): 'nemlendirici',
    RegExp(r'\bmoisturizers?\b', caseSensitive: false): 'nemlendirici',
    RegExp(r'\bprimer\b', caseSensitive: false): 'makyaj bazı',
    RegExp(r'\bcleanser\b', caseSensitive: false): 'yüz temizleyici',
    RegExp(r'\btoner\b', caseSensitive: false): 'tonik',
    RegExp(r'\bsunscreen\b', caseSensitive: false): 'güneş kremi',
    RegExp(r'\bskincare\b', caseSensitive: false): 'cilt bakımı',
    RegExp(r'\bglow\b', caseSensitive: false): 'doğal parlaklık',
    RegExp(r'\bmatte\b', caseSensitive: false): 'mat',
    RegExp(r'\bdewy\b', caseSensitive: false): 'canlı ve ıslak görünümlü',
    // LLM Halüsinasyon Sızıntıları (Özellikle Rusça vb.)
    RegExp(r'\bпоэтому\b', caseSensitive: false): 'bu yüzden',
    RegExp(r'\bи\b', caseSensitive: false): 've',
    RegExp(r'\bдля\b', caseSensitive: false): 'için',
  };
  for (final e in latinToTr.entries) {
    s = s.replaceAllMapped(e.key, (_) => e.value);
  }
  return s.trim();
}

String _sanitizeGarbledBeautyPhrases(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(RegExp(r'ton\s+açıklırlarla', caseSensitive: false), 'açık ya da doğal bir tonda')
      .replaceAll(RegExp(r'açıklırlarla', caseSensitive: false), 'açık tonlarla')
      .trim();
}

String _fixDudakPlusOjeInSentence(String text) {
  if (text.isEmpty) return text;
  final dudakRe = RegExp(r'dudak', caseSensitive: false);
  final ojeWord = RegExp(r'\boje\b', caseSensitive: false);
  if (!dudakRe.hasMatch(text) || !ojeWord.hasMatch(text)) return text;

  final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
  return parts.map((sentence) {
    if (!dudakRe.hasMatch(sentence) || !ojeWord.hasMatch(sentence)) {
      return sentence;
    }
    if (RegExp(r'tırnak', caseSensitive: false).hasMatch(sentence)) {
      return sentence.replaceAllMapped(
        RegExp(r'(dudak[^\n.!?]{0,52}?)\s+[üÜ]zer(?:ine)?(?:\s+[üÜ]?zerine)?(?:\s+[iİ]çin)?\s+[öÖ]?je\b', caseSensitive: false),
        (m) => '${m[1]} için ruj',
      );
    }
    var t = sentence;
    t = t.replaceAllMapped(
      RegExp(r'(dudak[^\n.!?]{0,48}?)(?:(?:için|üzerine|kenarına)\s+)?(?:bir\s+)?oje\b', caseSensitive: false),
      (m) => '${m[1]} için ruj',
    );
    return t.replaceAll(ojeWord, 'ruj');
  }).join(' ');
}

OutfitSuggestion _polishSuggestionFields(OutfitSuggestion o, {required bool beautyOn}) {
  String pol(String x) => _sanitizeGarbledBeautyPhrases(_sanitizeTurkishOnly(x)).trim();

  final desc = pol(o.outfitDescription);
  final mot = pol(o.motivationMessage);
  final mk = beautyOn ? pol(o.makeupTips) : '';
  final sk = beautyOn ? pol(o.skincareTips) : '';

  final mkFixed = beautyOn ? _sanitizeBeautyCopy(_fixDudakPlusOjeInSentence(mk), isMakeup: true) : '';
  final skFixed = beautyOn ? _sanitizeBeautyCopy(_fixDudakPlusOjeInSentence(sk), isMakeup: false) : '';

  return OutfitSuggestion(
    styleName: pol(o.styleName),
    itemIds: o.itemIds,
    outfitDescription: desc,
    makeupTips: mkFixed,
    skincareTips: skFixed,
    motivationMessage: mot,
  );
}

String _sanitizeBeautyCopy(String text, {required bool isMakeup}) {
  if (text.isEmpty) return text;
  var s = text;
  if (!isMakeup) {
    s = s.replaceAllMapped(
      RegExp(r'yüz\w*[ıiuü]\w*\s+[üÜ]zer(?:ine)?\s+(?:bir\s+)?oje\b', caseSensitive: false),
      (_) => 'tırnaklara uygun renk seçin',
    );
  }
  if (isMakeup) {
    s = s.replaceAllMapped(
      RegExp(r'(dudak[^\s,.;:!?]{0,36})\s+(?:(?:için|üzerine|kenarına)\s+)?(?:bir\s+)?oje\b', caseSensitive: false),
      (m) => '${m[1]} için ruj veya tint',
    );
  }
  return s.trim();
}

String _varietyDirective(int seed) {
  const directives = [
    'Birinci kombinde sofistike ve ciddi, ikinci kombinde enerjik ve spor, üçüncü kombinde rahat ve doğal bir stilist dili kullan.',
    'Her kombinin motivasyon mesajını farklı bir konseptten ver: 1. Özgüven, 2. Güzellik/Aura, 3. Konfor ve Rahatlık.',
    'Kombin açıklamalarında tekrara düşme. Bir kombinde renk uyumuna, diğerinde kumaşların kontrastına, diğerinde mekana uyuma vurgu yap.',
    'Makyaj ve cilt bakımı önerilerini tamamen değiştir. Birinde gözleri, diğerinde dudakları, diğerinde cilt parlaklığını öne çıkar.',
  ];
  return directives[seed.abs() % directives.length];
}

String _beautyCoherenceRules() {
  return '''
MAKYAJ VE CİLT BAKIMI KURALLARI (YASAKLAR VE ZORUNLULUKLAR):
1. YASAK: "Doğal makyaj yap", "Cildini temizle ve nemlendir" gibi tembel ve klişe cümleler KESİNLİKLE YASAKTIR.
2. ZORUNLULUK: Makyaj önerisi kombinin RENKLERİYLE zıtlık veya uyum yakalamalıdır. (Örn: "Siyah kombini patlatmak için bordo mat ruj", "Kırmızı kazağı dengelemek için sadece toprak tonlarında far").
3. ZORUNLULUK: Cilt bakımı hava durumuna ve etkinliğe özel olmalıdır. (Örn: "Evde kendine vakit ayırdığın bu günde cildini yorma, sadece bariyer onarıcı cica maskeni yap").
4. KUSURSUZ TÜRKÇE: Araya yabancı dilde veya Rusça/Kiril alfabesinde kelimeler KESİNLİKLE GİREMEZ.
''';
}

String _clean(String raw) {
  return raw
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'\*(.+?)\*'),     (m) => m[1]!)
      .replaceAll(RegExp(r'#+\s*'),               '')
      .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\n{3,}'),              '\n\n')
      .trim();
}

// ---------------------------------------------------------------------------
// Kombin önerisi veri modeli
// ---------------------------------------------------------------------------
class OutfitSuggestion {
  final String styleName;
  final List<String> itemIds;
  final String outfitDescription;
  final String makeupTips;
  final String skincareTips;
  final String motivationMessage;

  const OutfitSuggestion({
    required this.styleName,
    required this.itemIds,
    required this.outfitDescription,
    required this.makeupTips,
    required this.skincareTips,
    required this.motivationMessage,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    final rawIds = List<String>.from(json['itemIds'] as List? ?? []);
    final cleanIds = rawIds
        .map((id) => id.startsWith('ID:') ? id.substring(3) : id)
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    return OutfitSuggestion(
      styleName:         _clean(json['styleName']         as String? ?? 'Günlük Şıklık'),
      itemIds:           cleanIds,
      outfitDescription: _clean(json['outfitDescription'] as String? ?? ''),
      makeupTips:        _clean(json['makeupTips']        as String? ?? ''),
      skincareTips:      _clean(json['skincareTips']      as String? ?? ''),
      motivationMessage: _clean(json['motivationMessage'] as String? ?? ''),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  const ChatMessage({required this.role, required this.content});
}

// ---------------------------------------------------------------------------
// AI Servisi — Groq
// ---------------------------------------------------------------------------
class AIService {
  static const String _chatEndpoint = '${ApiConfig.groqBaseUrl}/chat/completions';

  String _buildClothingItemLine(ClothingItem i) {
    final fit = i.fit != null ? " | Kalıp: ${i.fit}" : "";
    final fabric = i.fabric != null ? " | Kumaş: ${i.fabric}" : "";
    final style = i.style != null ? " | Tarz: ${i.style}" : "";
    final subCategory = i.subCategory != null ? " | Alt Kategori: ${i.subCategory}" : "";
    return '• ID:${i.id} | Kategori: ${i.category}$subCategory | Renkler: ${i.colors.join(", ")} | Mevsim: ${i.seasons.join(", ")}$fit$fabric$style';
  }

  // -------------------------------------------------------------------------
  // KOMBİN ÖNERİSİ — YENİ NESİL SINIRSIZ ÇOKLU KOMBİN PROMPTU
  // -------------------------------------------------------------------------
  Future<List<OutfitSuggestion>> getOutfitSuggestion({
    required List<ClothingItem> items,
    required WeatherModel weather,
    required String mood,
    required String occasion,
    String? zodiacSign,
    String? customPrompt,
    bool includeMakeupSkincare = true,
  }) async {
    _checkApiKey();

    final varietySeed = DateTime.now().millisecondsSinceEpoch ^ items.length * 17;
    final validIds = items.map((i) => i.id).toSet();

    final clothingList = items.isEmpty
        ? 'Gardırop boş.'
        : items.map((i) => _buildClothingItemLine(i)).join('\n');

    final validIdList = items.map((i) => i.id).join(', ');

    final zodiacLine = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? 'Kullanıcının burcu: $zodiacSign. Stil yorumlarında ve motivasyon mesajında bu burcun karakteristik kodlarına profesyonel bir astrolog gibi değin.'
        : '';

    final systemPrompt =
        'Sen dünyanın en iyi kişisel moda stilisti ve güzellik uzmanısın. '
        'Görevin, kullanıcının gardırobundaki parçaları kullanarak ona MÜKEMMEL KOMBİNLER sunmaktır. $zodiacLine\n'
        'ÇOK ÖNEMLİ KURAL: SADECE VE SADECE kusursuz TÜRKÇE konuşacaksın. Yanıtının hiçbir yerinde İngilizce, Rusça, Fransızca veya başka bir dilde tek bir kelime bile bulunmamalıdır.\n'
        'Yanıtını HER ZAMAN geçerli bir JSON nesnesi olarak ver.';

    final customPromptBlock = (customPrompt != null && customPrompt.trim().isNotEmpty)
        ? '''
KULLANICI ÖZEL İSTEĞİ: "${customPrompt.trim()}"
DİKKAT: Kullanıcı kırmızı istiyorsa kırmızı bir parça seç AMA kombini siyah, beyaz, kot gibi nötr renklerle tamamlayıp DENGELE. Sadece kırmızı kazak verip bırakma!
'''
        : '';

    final beautyRestriction = includeMakeupSkincare
        ? ''
        : 'ÖNEMLİ: Kullanıcı makyaj/cilt bakımı İSTEMİYOR. "makeupTips" ve "skincareTips" değerlerini kesinlikle boş string ("") olarak bırak.';

    final beautyJsonHints = includeMakeupSkincare
        ? '''
      "makeupTips": "Kombin renkleriyle eşleşen spesifik bir makyaj tüyosu (Sadece Türkçe)",
      "skincareTips": "Havaya/mekana uygun 1 adet nokta atışı cilt bakım rutini (Sadece Türkçe)",'''
        : '''
      "makeupTips": "",
      "skincareTips": "",''';

    final userPrompt = '''
GARDIROP (SADECE BUNLARI KULLANABİLİRSİN):
$clothingList

GEÇERLİ ID LİSTESİ: $validIdList

$customPromptBlock
BUGÜNÜN KOŞULLARI:
Hava: ${weather.conditionForPrompt}
Ruh hali: $mood
Etkinlik: $occasion

STİLİST KURALLARI (HAYATİ ÖNEM TAŞIR):
1. SINIRSIZ ÇOKLU KOMBİN: Gardıroptaki kıyafetlerle EN AZ 3, MÜMKÜNSE YAPABİLDİĞİN KADAR ÇOK FARKLI KOMBİN ALTERNATİFİ ÜRET. Hiçbir üst sınır yok! Tüm mantıklı ve uyumlu eşleşmeleri kullanıcıya sun. Asla 1 veya 2 kombinle yetinme!
2. EKSİKSİZ KOMBİN (KURAL): Bir kombin asla yarım olamaz. Üst giyim seçtiysen KESİNLİKLE bir Alt Giyim (Pantolon/Etek) seçeceksin. Her kombinde Ayakkabı olmak zorundadır. Elbise seçtiysen alt giyime gerek yoktur.
3. BAĞLAM UYUMU: Etkinlik "Ev" veya ruh hali "Sakin" ise mini etek, abiye, topuklu önerme. Ev ortamına uygun rahat şeyler seç.
4. ÇEŞİTLİLİK: Her kombinin ruhu, parçaları ve senin yazdığın açıklamalar BİRBİRİNDEN FARKLI olsun. Aynı parçaları sürekli döndürüp durma.
5. DİL: Sadece TÜRKÇE kullan. Rusça (поэтому, для vb.) veya İngilizce kelimeler sızdırma.
${_varietyDirective(varietySeed)}
${includeMakeupSkincare ? _beautyCoherenceRules() : ''}
$beautyRestriction

JSON FORMATI (Sadece bu yapıyı döndür. Dikkat et, "outfits" listesi içinde MÜMKÜN OLDUĞUNCA ÇOK obje olmalı, en az 3):
{
  "outfits": [
    {
      "styleName": "1. Kombinin Çarpıcı İsmi",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "Neden bu parçaları eşleştirdiğini anlatan stilist yorumu.",$beautyJsonHints
      "motivationMessage": "Güne başlarken onu harika hissettirecek motivasyon sözü."
    },
    {
      "styleName": "2. Kombinin Farklı İsmi",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "Bu alternatifin neden farklı ve güzel olduğunu anlatan yorum.",$beautyJsonHints
      "motivationMessage": "Bu kombine özel bambaşka bir motivasyon sözü."
    },
    {
      "styleName": "3. Kombinin İsmi",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "Üçüncü alternatif için şık bir açıklama.",$beautyJsonHints
      "motivationMessage": "Son bir harika motivasyon cümlesi."
    }
  ]
}''';

    final raw = await _callGroq(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user',   'content': userPrompt},
      ],
      maxTokens: 4096,
      temperature: 0.85, // Biraz daha yaratıcılık ve çeşitlilik için sıcaklık artırıldı
    );

    final jsonStr = _extractJson(raw);
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['outfits'] as List? ?? [];
      if (list.isEmpty) throw 'Boş liste';

      final outfits = list
          .map((o) => OutfitSuggestion.fromJson(o as Map<String, dynamic>))
          .map((o) => OutfitSuggestion(
                styleName: o.styleName,
                itemIds: o.itemIds.where(validIds.contains).toList(),
                outfitDescription: o.outfitDescription,
                makeupTips: includeMakeupSkincare ? o.makeupTips : '',
                skincareTips: includeMakeupSkincare ? o.skincareTips : '',
                motivationMessage: o.motivationMessage,
              ))
          .map((o) => _polishSuggestionFields(o, beautyOn: includeMakeupSkincare))
          .where((o) => o.itemIds.isNotEmpty)
          .toList();

      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }

  // -------------------------------------------------------------------------
  // KÖR NOKTA ANALİZİ
  // -------------------------------------------------------------------------
  Future<List<OutfitSuggestion>> getBlindSpotSuggestion({
    required List<ClothingItem> forgottenItems,
    required List<ClothingItem> allItems,
    String? zodiacSign,
  }) async {
    _checkApiKey();

    final varietySeed = DateTime.now().millisecondsSinceEpoch ^ forgottenItems.length * 31;
    final validIds = allItems.map((i) => i.id).toSet();

    final forgottenList = forgottenItems.map((i) {
      final days = DateTime.now().difference(i.lastWornAt ?? i.createdAt).inDays;
      return '${_buildClothingItemLine(i)} | $days gündür giyilmedi';
    }).join('\n');

    final allList = allItems.map((i) => _buildClothingItemLine(i)).join('\n');
    final validIdList = allItems.map((i) => i.id).join(', ');

    final zodiacLine = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? ' Kullanıcı burcu: $zodiacSign. Tarz yorumlarında burç özelliklerini hesaba kat.'
        : '';

    final systemPrompt =
        'Sen STILYA uygulamasının yapay zeka stil asistanısın. '
        'Görevin kullanıcının uzun süredir giymediği kıyafetleri yeniden keşfettirmek.$zodiacLine '
        'SADECE VE SADECE TÜRKÇE KONUŞ. Yabancı kelimeler sızdırma. '
        'Yanıtını HER ZAMAN geçerli bir JSON nesnesi olarak ver.';

    final varietyBlock = '''
ÇEŞİTLENDİRME:
${_varietyDirective(varietySeed)}
${_beautyCoherenceRules()}
''';

    final userPrompt = '''
$varietyBlock
UZUN SÜREDİR GİYİLMEYEN KIYAFETLER (Her kombinde en az biri kullanılmalı):
$forgottenList

TÜM GARDİROP (Kombinleri tamamlamak için kullanabilirsin):
$allList

GEÇERLİ ID LİSTESİ: $validIdList

KESİN KURALLAR:
1. SINIRSIZ ÇOKLU KOMBİN: Lütfen EN AZ 3, MÜMKÜNSE YAPABİLDİĞİN KADAR ÇOK FARKLI KOMBİN alternatifi üret. Sınır yok! "outfits" dizisine üretebildiğin kadar çok obje ekle.
2. EKSİKSİZ KOMBİN: Üst giyim varsa alt giyim olmalı. Kombinler eksik olamaz.
3. Her kombinde en az bir "uzun süredir giyilmeyen" parça KESİNLİKLE OLMALI.
4. SADECE TÜRKÇE DİLİNİ KULLAN.

JSON FORMATI (Sadece bu yapıyı döndür. "outfits" içinde mümkün olduğunca çok obje olsun, en az 3):
{
  "outfits": [
    {
      "styleName": "1. Kombin",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "Neden bu parçayı yeniden keşfetmen gerektiğini anlatan stil notu",
      "makeupTips": "Kombinle uyumlu makyaj önerisi",
      "skincareTips": "Cilt bakım tavsiyesi",
      "motivationMessage": "Gardırobundaki bu gizli hazineyi keşfetmen için mesaj"
    },
    {
      "styleName": "2. Kombin",
      "itemIds": ["..."],
      "outfitDescription": "...",
      "makeupTips": "...",
      "skincareTips": "...",
      "motivationMessage": "..."
    }
  ]
}''';

    final raw = await _callGroq(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: 4096,
      temperature: 0.85,
    );

    final jsonStr = _extractJson(raw);
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['outfits'] as List? ?? [];
      if (list.isEmpty) throw 'Boş liste';

      final outfits = list
          .map((o) => OutfitSuggestion.fromJson(o as Map<String, dynamic>))
          .map((o) => OutfitSuggestion(
                styleName: o.styleName,
                itemIds: o.itemIds.where(validIds.contains).toList(),
                outfitDescription: o.outfitDescription,
                makeupTips: o.makeupTips,
                skincareTips: o.skincareTips,
                motivationMessage: o.motivationMessage,
              ))
          .map((o) => _polishSuggestionFields(o, beautyOn: true))
          .where((o) => o.itemIds.isNotEmpty)
          .toList();

      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }

  // -------------------------------------------------------------------------
  // CHAT
  // -------------------------------------------------------------------------
  Future<String> chat({
    required List<ChatMessage> history,
    List<ClothingItem> clothingItems = const [],
    String? zodiacSign,
  }) async {
    _checkApiKey();

    final wardrobeSummary = clothingItems.isEmpty
        ? 'Gardırop henüz boş.'
        : clothingItems.map((i) => '${i.category} (${i.colors.join(", ")})').join(', ');

    final zodiacExtra = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? ' Güneş burcu: $zodiacSign — önerilerinde renk ve enerji tonunu bu burca göre kişiselleştir. '
        : '';

    final systemPrompt =
        'Sen STILYA uygulamasının kişisel moda ve stil editörüsün. '
        'Kullanıcıyla samimi, destekleyici ve ilham verici bir üslupla '
        'YALNIZCA akıcı ve doğal TÜRKÇE konuş; İngilizce, Rusça veya '
        'gereksiz yabancı harman kesinlikle kullanma. Moda kuralları, renk uyumları ve '
        'güzellik konularında uzmansın.$zodiacExtra Kullanıcının gardırobu: $wardrobeSummary';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {
            'role':    m.role == 'model' ? 'assistant' : m.role,
            'content': m.content,
          }),
    ];

    final raw = await _callGroq(messages: messages, temperature: 0.72);
    return _sanitizeGarbledBeautyPhrases(
      _fixDudakPlusOjeInSentence(
        _sanitizeTurkishOnly(raw),
      ),
    );
  }

  Future<Map<String, dynamic>?> analyzeClothingImage(File imageFile, {int retryCount = 0}) async {
    if (ApiConfig.geminiApiKey == 'BURAYA_GEMINI_API_KEY_GELECEK' || ApiConfig.geminiApiKey.isEmpty) {
      throw 'Lütfen api_config.dart dosyasına Gemini API anahtarınızı ekleyin!';
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final systemPrompt =
          'Sen usta bir stilist ve moda asistanısın. Görevin, sana gönderilen kıyafet '
          'fotoğrafını analiz edip şu özelliklerini belirlemektir: Kategori (SADECE ŞUNLARDAN BİRİ: "Üst Giyim", "Alt Giyim", "Dış Giyim", "Elbise / Tulum", "Aksesuar", "Ayakkabı", "Çanta", "Diğer"), '
          'Alt Kategori / Tür (Çok net ol: "Etek", "Pantolon", "Şort", "Tişört", "Kazak", "Gömlek", "Ceket", "Elbise" vb.), '
          'Renkler (en fazla 2 ana renk), '
          'Mevsimler (kıyafetin uygun olduğu mevsimler), Kalıp/Kesim (Fit: dar, oversize, bol, v-yaka vs.), '
          'Kumaş (Pamuk, ipek, kot, deri, sentetik vs.), Desen (Düz renk, çizgili, çiçekli, kareli vs.), '
          'Tarz/Stil (Spor, şık, günlük/casual, vintage, gece vs.).\\n'
          'SADECE JSON formatında yanıt ver. Örnek Format:\\n'
          '{\\n'
          '  "category": "Alt Giyim",\\n'
          '  "subCategory": "Kot Etek",\\n'
          '  "colors": ["Beyaz", "Mavi"],\\n'
          '  "seasons": ["Yaz", "İlkbahar"],\\n'
          '  "fit": "Yırtmaçlı",\\n'
          '  "fabric": "Kot",\\n'
          '  "pattern": "Düz Renk",\\n'
          '  "style": "Günlük (Casual)"\\n'
          '}';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\\n\\nBu kıyafeti analiz et ve SADECE JSON olarak döndür.'},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      };

      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${ApiConfig.geminiApiKey}';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw 'Gemini boş yanıt döndürdü.';
        }
        
        final content = candidates[0]['content']['parts'][0]['text'] as String;
        final jsonStr = _extractJson(content);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } else if (response.statusCode == 503 && retryCount < 2) {
        await Future.delayed(const Duration(seconds: 3));
        return analyzeClothingImage(imageFile, retryCount: retryCount + 1);
      } else {
        throw 'Gemini API Hatası (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      throw e.toString();
    }
  }

  Future<String> _callGroq({
    required List<Map<String, String>> messages,
    int retryCount = 0,
    int maxTokens = 4096, // Çoklu kombinler uzun olacağı için token limitini yüksek tuttuk
    double temperature = 0.85,
  }) async {
    final response = await http
        .post(
          Uri.parse(_chatEndpoint),
          headers: {
            'Content-Type':  'application/json',
            'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model':       ApiConfig.groqModel,
            'messages':    messages,
            'temperature': temperature,
            'max_tokens':  maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 45));

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      case 400:
        throw 'İstek hatası (400): ${response.body}';
      case 401:
        throw 'Groq API anahtarı geçersiz. api_config.dart dosyasını kontrol et.';
      case 429:
        if (retryCount < 1) {
          await Future.delayed(const Duration(seconds: 5));
          return _callGroq(
            messages: messages,
            retryCount: retryCount + 1,
            maxTokens: maxTokens,
            temperature: temperature,
          );
        }
        throw 'İstek limiti aşıldı. Birkaç saniye bekleyip tekrar dene.';
      default:
        throw 'AI servisi hatası (${response.statusCode}): ${response.body}';
    }
  }
  /// Groq bazen JSON'u ```json … ``` bloğuna sarar — temizle.
  String _extractJson(String text) {
    final mdBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = mdBlock.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end   = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  void _checkApiKey() {
    if (ApiConfig.groqApiKey.isEmpty) {
      throw 'Groq API anahtarı eksik.\n'
          'Uygulamayı run_config.bat (Windows) veya run_config.sh (Mac/Linux) ile başlat,\n'
          'ya da VS Code launch.json içindeki GROQ_API_KEY değerini kontrol et.';
    }
  }
}
