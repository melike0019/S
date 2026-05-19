/// KURULUM TALİMATI
/// ─────────────────────────────────────────────────────────────────────────────
/// Bu dosya bir şablondur — içinde gerçek anahtar YOKTUR.
///
/// 1. Bu dosyayı kopyala: api_config.dart
/// 2. Gerçek anahtarlarını YAZ kısımlarına yaz.
/// 3. Kaydet — api_config.dart zaten .gitignore'dadır, git'e gitmez.
/// 4. Artık `flutter run` ile çalıştırabilirsin.
///
/// Anahtar kaynakları (ücretsiz):
///   OpenWeatherMap : https://openweathermap.org/api
///   Groq           : https://console.groq.com
///   Google Gemini  : https://aistudio.google.com/app/apikey
///   Hugging Face   : https://huggingface.co/settings/tokens
/// ─────────────────────────────────────────────────────────────────────────────
class ApiConfig {
  // Hava durumu — OpenWeatherMap
  static const String weatherApiKey = 'BURAYA_OPENWEATHERMAP_ANAHTARINI_YAZ';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // Yapay zeka — Groq (OpenAI uyumlu, ücretsiz)
  static const String groqApiKey = 'BURAYA_GROQ_ANAHTARINI_YAZ';
  static const String groqModel   = 'llama-3.3-70b-versatile';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';

  // Yapay zeka — Google Gemini (Görsel Analiz İçin)
  static const String geminiApiKey = 'BURAYA_GEMINI_ANAHTARINI_YAZ';

  // Yapay zeka — Hugging Face (Manken Üretimi İçin - Stable Diffusion 2.1)
  static const String huggingFaceToken = 'BURAYA_HUGGINGFACE_TOKENINI_YAZ';
}
