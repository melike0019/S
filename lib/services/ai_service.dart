import 'dart:convert';
import 'dart:io';
 
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
 
import '../core/api_config.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
 
// ---------------------------------------------------------------------------
// Türkçe Temizleyici — Halüsinasyon Önleme Katmanı
// ---------------------------------------------------------------------------
 
String _sanitizeTurkishOnly(String text) {
  if (text.isEmpty) return text;
  var s = text;
 
  // ── Rusça bağlaçlar ve kelimeler ──
  final russianMap = <RegExp, String>{
    RegExp(r'\bпоэтому\b', caseSensitive: false): 'bu nedenle',
    RegExp(r'\bи\b'): 've',
    RegExp(r'\bдля\b', caseSensitive: false): 'için',
    RegExp(r'\bно\b'): 'ama',
    RegExp(r'\bили\b', caseSensitive: false): 'ya da',
    RegExp(r'\bкак\b', caseSensitive: false): 'nasıl',
    RegExp(r'\bже\b'): 'ise',
    RegExp(r'\bчто\b', caseSensitive: false): 'bu',
    RegExp(r'\bбольше\b', caseSensitive: false): 'daha fazla',
    RegExp(r'\bможно\b', caseSensitive: false): 'mümkün',
  };
  for (final e in russianMap.entries) {
    s = s.replaceAllMapped(e.key, (_) => e.value);
  }
 
  // ── İngilizce kozmetik / moda terimleri ──
  final englishMap = <RegExp, String>{
    RegExp(r'\bglow\b', caseSensitive: false): 'doğal parlaklık',
    RegExp(r'\bdewy\b', caseSensitive: false): 'ışıltılı',
    RegExp(r'\bmatte\b', caseSensitive: false): 'mat',
    RegExp(r'\bprimer\b', caseSensitive: false): 'makyaj bazı',
    RegExp(r'\bskincare\b', caseSensitive: false): 'cilt bakımı',
    RegExp(r'\bcleanser\b', caseSensitive: false): 'temizleyici',
    RegExp(r'\btoner\b', caseSensitive: false): 'tonik',
    RegExp(r'\bsunscreen\b', caseSensitive: false): 'güneş kremi',
    RegExp(r'\bmoisturiz[ei]r\b', caseSensitive: false): 'nemlendirici',
    RegExp(r'\bhydrat\w+\b', caseSensitive: false): 'nemlendirici',
    RegExp(r'\bniacinamide\b', caseSensitive: false): 'niasinamid',
    RegExp(r'\bhyaluronic\b', caseSensitive: false): 'hiyalüronik asit',
    RegExp(r'\b[Ss][Pp][Ff]\s*\d+\b'): 'güneş koruyucu',
    RegExp(r'\boutfit\b', caseSensitive: false): 'kombin',
    RegExp(r'\blook\b', caseSensitive: false): 'görünüm',
    RegExp(r'\bstyle\b', caseSensitive: false): 'stil',
    RegExp(r'\bcasual\b', caseSensitive: false): 'günlük',
    RegExp(r'\bchic\b', caseSensitive: false): 'şık',
    RegExp(r'\belegant\b', caseSensitive: false): 'zarif',
    RegExp(r'\bmorning routine\b', caseSensitive: false): 'sabah rutini',
    RegExp(r'\bdaily routine\b', caseSensitive: false): 'günlük rutin',
    RegExp(r'\bnaturally\b', caseSensitive: false): 'doğal biçimde',
  };
  for (final e in englishMap.entries) {
    s = s.replaceAllMapped(e.key, (_) => e.value);
  }
 
  // ── Güzellik metni hataları ──
  s = s
      .replaceAll(RegExp(r'ton\s+açıklırlarla', caseSensitive: false),
          'açık tonlarla')
      .replaceAll(
          RegExp(r'açıklırlarla', caseSensitive: false), 'açık tonlarla')
      .replaceAll(RegExp(r'dudak[^\n.!?]{0,40}oje\b', caseSensitive: false),
          (match) => match.group(0)!.replaceAll(
              RegExp(r'\boje\b', caseSensitive: false), 'ruj'))
      .replaceAll(
          RegExp(r'tırnak[^\n.!?]{0,30}ruj\b', caseSensitive: false),
          (match) => match
              .group(0)!
              .replaceAll(RegExp(r'\bruj\b', caseSensitive: false), 'oje'));
 
  return s.trim();
}
 
// ---------------------------------------------------------------------------
// Markdown Temizleyici
// ---------------------------------------------------------------------------
String _clean(String raw) {
  return raw
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!)
      .replaceAll(RegExp(r'#+\s*'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
 
// ---------------------------------------------------------------------------
// Çeşitlilik Direktifi — Her çağrıda farklı bir stil açısı
// ---------------------------------------------------------------------------
String _varietyDirective(int seed) {
  const directives = [
    'Her kombinde farklı bir stil konsepti kullan: 1.kombinde sofistike/şehirli, 2.kombinde enerjik/dinamik, 3.kombinde rahat/doğal dil.',
    'Motivasyon mesajlarını üç farklı konseptten ver: 1.özgüven teması, 2.güzellik/aura teması, 3.konfor/rahatlık teması.',
    'Kombin açıklamalarında tekrardan kaçın: birinde renk uyumuna, diğerinde kumaş kontrastına, diğerinde ortama uyuma odaklan.',
    'Makyaj önerilerini çeşitlendir: birinde göz vurgusu, diğerinde dudak vurgusu, diğerinde cilt parlaklığı öne çıksın.',
  ];
  return directives[seed.abs() % directives.length];
}
 
// ---------------------------------------------------------------------------
// Güzellik Kuralları Bloğu
// ---------------------------------------------------------------------------
String _beautyRules() => '''
MAKYAJ & CİLT BAKIMI — KESİN KURALLAR:
1. YASAK: "Doğal makyaj yap", "Cildini temizle ve nemlendir" gibi GENEL ve KLİŞE cümleler kullanma.
2. ZORUNLU: Makyaj önerisi kombinin ana rengiyle DOĞRUDAN ilişkili olmalı.
   Örnek: "Siyah kombinini tamamlamak için bordo mat ruj" veya "Toprak tonlu kombine uygun bronz far".
3. ZORUNLU: Cilt bakımı hava durumu VE ortama özgü olmalı.
   Örnek: "Evde geçireceğin bu sakin günde cilt bariyerini güçlendirmek için cica maske uygula."
4. YASAK: İngilizce (glow, dewy, SPF, primer, cleanser) veya Rusça (поэтому, и, для) kelime sızdırma.
''';
 
// ---------------------------------------------------------------------------
// Kombin Önerisi Veri Modeli
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
      styleName: _clean(json['styleName'] as String? ?? 'Günlük Şıklık'),
      itemIds: cleanIds,
      outfitDescription:
          _clean(json['outfitDescription'] as String? ?? ''),
      makeupTips: _clean(json['makeupTips'] as String? ?? ''),
      skincareTips: _clean(json['skincareTips'] as String? ?? ''),
      motivationMessage:
          _clean(json['motivationMessage'] as String? ?? ''),
    );
  }
}
 
// ---------------------------------------------------------------------------
// Chat Mesaj Modeli
// ---------------------------------------------------------------------------
class ChatMessage {
  final String role;
  final String content;
  const ChatMessage({required this.role, required this.content});
}
 
// ---------------------------------------------------------------------------
// AI Servisi
// ---------------------------------------------------------------------------
class AIService {
  // ── Model Seçimi ──
  // Kombin önerisi & chat → Groq (deepseek-r1-distill-llama-70b)
  //   → En az halüsinasyon, Türkçe JSON en tutarlı, hız üstün
  // Kıyafet analizi      → Gemini 2.5 Flash
  //   → Görsel anlama zorunlu, tek seferlik istek
 
  static const String _groqEndpoint =
      '${ApiConfig.groqBaseUrl}/chat/completions';
 
  // Kombin önerisi için deepseek, chat için llama kullan
  static const String _outfitModel = 'deepseek-r1-distill-llama-70b';
  static const String _chatModel = 'llama-3.3-70b-versatile';
 
  // ---------------------------------------------------------------------------
  // Kıyafet Satır Oluşturucu
  // ---------------------------------------------------------------------------
  String _buildItemLine(ClothingItem i) {
    final parts = <String>[
      'ID:${i.id}',
      'Kategori:${i.category}',
      if (i.subCategory != null) 'AltKat:${i.subCategory}',
      'Renkler:${i.colors.join("/")}',
      'Mevsim:${i.seasons.join("/")}',
      if (i.fit != null) 'Kalıp:${i.fit}',
      if (i.fabric != null) 'Kumaş:${i.fabric}',
      if (i.style != null) 'Tarz:${i.style}',
      if (i.pattern != null) 'Desen:${i.pattern}',
    ];
    return '• ${parts.join(" | ")}';
  }
 
  // ---------------------------------------------------------------------------
  // Parçaları sonradan temizle
  // ---------------------------------------------------------------------------
  OutfitSuggestion _polish(OutfitSuggestion o, {required bool beautyOn}) {
    String p(String x) =>
        _sanitizeTurkishOnly(_clean(x)).trim();
 
    return OutfitSuggestion(
      styleName: p(o.styleName),
      itemIds: o.itemIds,
      outfitDescription: p(o.outfitDescription),
      makeupTips: beautyOn ? p(o.makeupTips) : '',
      skincareTips: beautyOn ? p(o.skincareTips) : '',
      motivationMessage: p(o.motivationMessage),
    );
  }
 
  // ---------------------------------------------------------------------------
  // KOMBİN ÖNERİSİ
  // ---------------------------------------------------------------------------
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
 
    final seed = DateTime.now().millisecondsSinceEpoch ^ items.length * 31;
    final validIds = items.map((i) => i.id).toSet();
 
    final clothingList = items.isEmpty
        ? 'Gardırop boş.'
        : items.map(_buildItemLine).join('\n');
 
    final validIdList = items.map((i) => i.id).join(', ');
 
    // Ev/Sakin bağlam koruyucu
    final bool isRelaxedContext =
        occasion == 'Ev' || mood == 'Sakin' || mood == 'sakin';
 
    final contextGuard = isRelaxedContext
        ? '''
BAĞLAM UYARISI — EV / SAKİN MOD:
• Mini etek, abiye, gece elbisesi, topuklu ayakkabı KESİNLİKLE önerme.
• Sadece ev içine uygun rahat, yumuşak veya casual parçalar seç.
• "Gece çıkışı", "ofis" veya "parti" tarzı kombinlere gitme.
'''
        : '';
 
    final zodiacBlock = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? '''
BURÇ ENTEGRASYONu — $zodiacSign:
Profesyonel bir stilist-astrolog gibi $zodiacSign burcunun karakteristik renk
kodlarını, enerji tonunu ve tarz özelliklerini kombinlere ve motivasyon
mesajlarına yansıt. Klişe burç yorumu değil; gerçek stil önerisi yap.
'''
        : '';
 
    final customBlock =
        (customPrompt != null && customPrompt.trim().isNotEmpty)
            ? '''
KULLANICI ÖZEL İSTEĞİ: "${customPrompt.trim()}"
→ Bu isteği göz önünde bulundur; ancak kombinlerin tamamını bu kısıtlamayla sınırlama.
  Örn: "kırmızı istiyorum" → en az bir kombinde kırmızı parça kullan,
  ama diğer kombinlerde gardırobun tüm olanaklarını kullan.
'''
            : '';
 
    final beautyJsonBlock = includeMakeupSkincare
        ? '''
      "makeupTips": "Kombinin ana rengiyle ilişkili spesifik makyaj önerisi (SADECE TÜRKÇE)",
      "skincareTips": "Hava/ortama özgü 1 cilt bakım rutini (SADECE TÜRKÇE)",'''
        : '''
      "makeupTips": "",
      "skincareTips": "",''';
 
    final systemPrompt =
        'Sen dünyanın en iyi kişisel moda stilistrsin. '
        'Görevin kullanıcının gardırobundaki GERÇEK parçalarla '
        'MÜMKÜN OLDUĞUNCA ÇOK FARKLI ve EKSİKSİZ kombin önermektir. '
        'SADECE VE SADECE kusursuz TÜRKÇE kullanacaksın. '
        'İngilizce, Rusça veya başka dilde TEK BİR KELIME bile sızdırma. '
        'Yanıtın HER ZAMAN geçerli bir JSON nesnesi olsun — başka hiçbir şey ekleme.';
 
    final userPrompt = '''
$zodiacBlock
$contextGuard
$customBlock
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
GARDIROP (SADECE BUNLARI KULLANABİLİRSİN)
━━━━━━━━━━━━━━━━━━━━━━━━━━
$clothingList
 
GEÇERLİ ID LİSTESİ: $validIdList
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
BUGÜNÜN KOŞULLARI
━━━━━━━━━━━━━━━━━━━━━━━━━━
Hava: ${weather.conditionForPrompt}
Ruh Hali: $mood
Etkinlik: $occasion
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
STİLİST KURALLARI — HER BİRİ KRİTİK
━━━━━━━━━━━━━━━━━━━━━━━━━━
 
KURAL 1 — SINIRSIZ KOMBİN (EN KRİTİK):
Gardıroptaki parçalarla MÜMKÜN OLDUĞUNCA ÇOK kombin üret.
Minimum 3, ideal olarak çok daha fazla. "outfits" dizisine ne kadar
çok mantıklı kombin sığdırabilirsen o kadar ekle.
ASLA 1-2 kombinle yetinme. Limit yok.
 
KURAL 2 — EKSİKSİZ KOMBİN (KESİN):
• Üst Giyim seçtiysen → Alt Giyim (Pantolon/Etek/Şort) ZORUNLU.
• Her kombinde → Ayakkabı ZORUNLU.
• Elbise/Tulum seçtiysen → Alt Giyim gerekmez.
• Eksik kombin geçersizdir, öneri listesine dahil etme.
 
KURAL 3 — ÇEŞİTLİLİK:
Her kombinin parçaları, açıklaması, makyajı ve motivasyonu BİRBİRİNDEN FARKLI olsun.
Aynı parçaları tekrar tekrar döndürme.
${_varietyDirective(seed)}
 
KURAL 4 — SIFIR HALÜSİNASYON:
• SADECE geçerli ID listesindeki parçaları kullan.
• Listede olmayan hiçbir kıyafeti "var gibi" ekleme.
• itemIds içine SADECE yukarıdaki geçerli ID'leri yaz.
 
KURAL 5 — SIFIR YABANCI DİL:
Türkçe olmayan tek bir kelime bile yazarsan yanıt geçersiz sayılır.
${includeMakeupSkincare ? _beautyRules() : ''}
${includeMakeupSkincare ? '' : 'NOT: Kullanıcı makyaj/cilt bakımı istemiyor. makeupTips ve skincareTips BOŞ ("") olsun.'}
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
JSON FORMATI (SADECE BU YAPI — BAŞKA HİÇBİR ŞEY EKLEME)
━━━━━━━━━━━━━━━━━━━━━━━━━━
{
  "outfits": [
    {
      "styleName": "Kombinin Çarpıcı Türkçe İsmi",
      "itemIds": ["sadece_gecerli_id_1", "sadece_gecerli_id_2", "..."],
      "outfitDescription": "Bu kombinIn neden harika olduğunu anlatan stilist yorumu.",
$beautyJsonBlock
      "motivationMessage": "Bu kombine özel, özgün bir motivasyon cümlesi."
    },
    {
      "styleName": "İkinci Kombinin Farklı İsmi",
      "itemIds": ["..."],
      "outfitDescription": "...",
$beautyJsonBlock
      "motivationMessage": "..."
    }
  ]
}
 
HATIRLATMA: "outfits" dizisine mümkün olduğunca çok kombin ekle (en az 3).
Her kombin eksiksiz (üst+alt+ayakkabı veya elbise+ayakkabı) olmalı.''';
 
    final raw = await _callGroq(
      model: _outfitModel,
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: 6000,
      temperature: 0.75,
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
          .map((o) => _polish(o, beautyOn: includeMakeupSkincare))
          .where((o) => o.itemIds.isNotEmpty)
          .toList();
 
      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }
 
  // ---------------------------------------------------------------------------
  // KÖR NOKTA ANALİZİ
  // ---------------------------------------------------------------------------
  Future<List<OutfitSuggestion>> getBlindSpotSuggestion({
    required List<ClothingItem> forgottenItems,
    required List<ClothingItem> allItems,
    String? zodiacSign,
  }) async {
    _checkApiKey();
 
    final seed =
        DateTime.now().millisecondsSinceEpoch ^ forgottenItems.length * 53;
    final validIds = allItems.map((i) => i.id).toSet();
 
    final forgottenList = forgottenItems.map((i) {
      final days =
          DateTime.now().difference(i.lastWornAt ?? i.createdAt).inDays;
      return '${_buildItemLine(i)} | $days gündür giyilmedi';
    }).join('\n');
 
    final allList = allItems.map(_buildItemLine).join('\n');
    final validIdList = allItems.map((i) => i.id).join(', ');
 
    final zodiacBlock = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? 'Kullanıcı burcu: $zodiacSign. Bu burcun stil enerjisini yeniden keşif yorumuna yansıt.\n'
        : '';
 
    final systemPrompt =
        'Sen STILYA uygulamasının yapay zeka stil asistanısın. '
        'Görevin uzun süredir giyilmeyen kıyafetleri yeniden keşfettirmek. '
        '$zodiacBlock'
        'SADECE kusursuz TÜRKÇE kullan. Yabancı kelime sızdırma. '
        'Yanıtın HER ZAMAN geçerli JSON olsun.';
 
    final userPrompt = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━
UZUN SÜREDİR GİYİLMEYEN PARÇALAR
(Her kombinde en az biri ZORUNLU)
━━━━━━━━━━━━━━━━━━━━━━━━━━
$forgottenList
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
TÜM GARDİROP (Kombinleri tamamlamak için)
━━━━━━━━━━━━━━━━━━━━━━━━━━
$allList
 
GEÇERLİ ID LİSTESİ: $validIdList
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
KESİN KURALLAR
━━━━━━━━━━━━━━━━━━━━━━━━━━
 
KURAL 1 — SINIRSIZ KOMBİN:
Mümkün olduğunca çok kombin üret. Minimum 3, ideal çok daha fazla.
 
KURAL 2 — EKSİKSİZ KOMBİN:
• Üst Giyim → Alt Giyim (Pantolon/Etek) ZORUNLU.
• Her kombinde Ayakkabı ZORUNLU.
• Elbise/Tulum → Alt Giyim gerekmez.
 
KURAL 3 — UNUTULAN PARÇA:
Her kombinde yukarıdaki "uzun süredir giyilmeyen" listesinden
en az 1 parça KESİNLİKLE kullanılmalı.
 
KURAL 4 — ÇEŞİTLİLİK:
${_varietyDirective(seed)}
${_beautyRules()}
 
KURAL 5 — SADECE TÜRKÇE:
Tek bir yabancı kelime bile yasak.
 
━━━━━━━━━━━━━━━━━━━━━━━━━━
JSON FORMATI
━━━━━━━━━━━━━━━━━━━━━━━━━━
{
  "outfits": [
    {
      "styleName": "Yeniden Keşif Kombini İsmi",
      "itemIds": ["sadece_gecerli_id"],
      "outfitDescription": "Bu unutulan parçanın neden yeniden değerli olduğunu anlat.",
      "makeupTips": "Kombinin rengiyle ilişkili makyaj önerisi",
      "skincareTips": "Ortama uygun cilt bakım tavsiyesi",
      "motivationMessage": "Bu parçayı yeniden keşfetmek için özgün mesaj"
    }
  ]
}
 
"outfits" dizisine mümkün olduğunca çok kombin ekle (en az 3).''';
 
    final raw = await _callGroq(
      model: _outfitModel,
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: 6000,
      temperature: 0.75,
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
          .map((o) => _polish(o, beautyOn: true))
          .where((o) => o.itemIds.isNotEmpty)
          .toList();
 
      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }
 
  // ---------------------------------------------------------------------------
  // CHAT — Stil Asistanı
  // ---------------------------------------------------------------------------
  Future<String> chat({
    required List<ChatMessage> history,
    List<ClothingItem> clothingItems = const [],
    String? zodiacSign,
  }) async {
    _checkApiKey();
 
    final wardrobeSummary = clothingItems.isEmpty
        ? 'Gardırop henüz boş.'
        : clothingItems
            .map((i) => '${i.category}(${i.colors.join("/")})')
            .join(', ');
 
    final zodiacExtra = (zodiacSign != null && zodiacSign.isNotEmpty)
        ? ' Kullanıcının güneş burcu $zodiacSign — '
          'renk ve enerji önerilerini bu burcun karakterine göre kişiselleştir.'
        : '';
 
    final systemPrompt =
        'Sen STILYA uygulamasının kişisel moda ve stil editörüsün. '
        'Kullanıcıyla samimi, destekleyici ve ilham verici bir üslupla '
        'YALNIZCA akıcı ve doğal TÜRKÇE konuş. '
        'İngilizce, Rusça veya başka dilde tek bir kelime bile kullanma.$zodiacExtra '
        'Moda, renk uyumu ve güzellik konularında uzmansın. '
        'Kullanıcının gardırobu: $wardrobeSummary';
 
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {
            'role': m.role == 'model' ? 'assistant' : m.role,
            'content': m.content,
          }),
    ];
 
    final raw = await _callGroq(
      model: _chatModel,
      messages: messages,
      maxTokens: 1024,
      temperature: 0.70,
    );
 
    return _sanitizeTurkishOnly(raw);
  }
 
  // ---------------------------------------------------------------------------
  // KIYAFEt GÖRSEL ANALİZİ — Gemini 2.5 Flash
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> analyzeClothingImage(
    File imageFile, {
    int retryCount = 0,
  }) async {
    if (ApiConfig.geminiApiKey.isEmpty ||
        ApiConfig.geminiApiKey == 'BURAYA_GEMINI_API_KEY_GELECEK') {
      throw 'Lütfen api_config.dart dosyasına Gemini API anahtarınızı ekleyin!';
    }
 
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
 
      const systemPrompt =
          'Sen usta bir stilist ve moda asistanısın. '
          'Sana gönderilen kıyafet fotoğrafını analiz edip şu özellikleri belirle: '
          'Kategori (SADECE: "Üst Giyim", "Alt Giyim", "Dış Giyim", '
          '"Elbise / Tulum", "Aksesuar", "Ayakkabı", "Çanta", "Diğer"), '
          'Alt Kategori/Tür (Etek, Pantolon, Şort, Tişört, Kazak, Gömlek, Ceket, Elbise vb.), '
          'Renkler (en fazla 2 ana renk, Türkçe), '
          'Mevsimler (uygun mevsimler, Türkçe), '
          'Kalıp/Kesim (dar, oversize, bol, v-yaka vb.), '
          'Kumaş (Pamuk, ipek, kot, deri, sentetik vb.), '
          'Desen (Düz renk, çizgili, çiçekli, kareli vb.), '
          'Tarz/Stil (Spor, şık, günlük, vintage, gece vb.). '
          'SADECE JSON formatında yanıt ver. Başka hiçbir şey ekleme.';
 
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    '$systemPrompt\n\nBu kıyafeti analiz et ve SADECE JSON döndür:\n'
                    '{"category":"...","subCategory":"...","colors":["..."],'
                    '"seasons":["..."],"fit":"...","fabric":"...","pattern":"...","style":"..."}'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
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
 
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'
          '?key=${ApiConfig.geminiApiKey}';
 
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45));
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw 'Gemini boş yanıt döndürdü.';
        }
        final content =
            candidates[0]['content']['parts'][0]['text'] as String;
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
      rethrow;
    }
  }
 
  // ---------------------------------------------------------------------------
  // GROQ API Çağrısı
  // ---------------------------------------------------------------------------
  Future<String> _callGroq({
    required String model,
    required List<Map<String, String>> messages,
    int retryCount = 0,
    int maxTokens = 4096,
    double temperature = 0.75,
  }) async {
    final response = await http
        .post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 60));
 
    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      case 400:
        throw 'İstek hatası (400): ${response.body}';
      case 401:
        throw 'Groq API anahtarı geçersiz. api_config.dart dosyasını kontrol et.';
      case 429:
        if (retryCount < 2) {
          await Future.delayed(Duration(seconds: 5 + retryCount * 3));
          return _callGroq(
            model: model,
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
 
  // ---------------------------------------------------------------------------
  // JSON Çıkarıcı — Markdown bloklarını temizle
  // ---------------------------------------------------------------------------
  String _extractJson(String text) {
    // <think>...</think> bloklarını temizle (deepseek modeli için)
    var clean = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
 
    // ```json ... ``` bloklarını temizle
    final mdBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = mdBlock.firstMatch(clean);
    if (match != null) return match.group(1)!.trim();
 
    // Direkt JSON bul
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return clean.substring(start, end + 1);
    }
    return clean;
  }
 
  // ---------------------------------------------------------------------------
  // API Key Kontrolü
  // ---------------------------------------------------------------------------
  void _checkApiKey() {
    if (ApiConfig.groqApiKey.isEmpty) {
      throw 'Groq API anahtarı eksik.\n'
          'Uygulamayı run_config.bat (Windows) veya run_config.sh (Mac/Linux) ile başlat.';
    }
  }
}
 