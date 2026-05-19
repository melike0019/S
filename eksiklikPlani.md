Sen Kıdemli bir Flutter Geliştiricisin. Aşağıda sana verdiğim "Stilya Projesi Eksikler Listesi"ndeki özellikleri sırasıyla projeye entegre etmeni istiyorum.

Bu süreci yönetirken şu KESİN KURALLARA uymalısın:  

1. TEK TEK İLERLE: Asla birden fazla özelliği aynı anda geliştirmeye çalışma. Sadece önceliği en yüksek olan ilk sıradaki özelliğe odaklan, gerekli kodlamaları yap ve o özelliği bitir.  
2. ONAY BEKLE: Bir özelliğin kodlamasını tamamladığında dur. Bana ne yaptığını kısaca özetle ve uygulamanın sorunsuz derlenip çalışıp çalışmadığını test etmem için benden ONAY bekle.  
3. GİT KOMUTLARINI VER: Ben sana "Tamam, çalışıyor" veya "Onaylıyorum" dedikten sonra, SADECE o geliştirmeye ait dosyaları kapsayan git add komutlarını ve standartlara uygun (conventional commits) bir git commit -m "feat/fix: açıklama" komutunu bana metin olarak ver.  
4. UZAK SUNUCUYA DOKUNMA (NO PUSH): Kesinlikle ama kesinlikle git push komutunu çalıştırma veya Github'a bir şey göndermeye çalışma. Gönderim işlemlerini ben manuel olarak yapacağım.  
5. SIRADAKİ GÖREVE GEÇ: Commit komutlarını bana verdikten sonra, listedeki bir sonraki göreve geçmek için hazır olduğunu belirt.  İşte sırayla, hatasız tamamlamanı istediğim eksikler listesi: 

 \[YENİ VE KRİTİK ÖZELLİKLER -

   1. &#x20;AI \& CORE ALTYAPI]Kullanıcı Doğum Tarihi ve Burç Entegrasyonu: Kullanıcı kayıt (register) sürecine doğum tarihi giriş alanı ekle. Girilen tarihe göre kullanıcının burcunu tespit et ve Firebase kullanıcı modeline kaydet. Bu burç bilgisini, kişilerin renk tercihi ve eğilimlerini etkilemesi için AI'a gönderilen ana prompta dinamik olarak dahil et.
   2. Özel Kombin Detayı Alanı: Ana sayfada, mood ve plan seçiminden sonra, "Kombin Öner" butonunun hemen üstüne bir metin giriş alanı (TextField) ekle. Kullanıcı buraya "bugün kırmızı ağırlıklı giyinmek istiyorum" gibi özel isteklerini ve plan detaylarını yazabilsin. Bu veriyi default AI promptuna bağla.
   3. Makyaj ve Cilt Bakım Tercihi Butonu: Ana sayfaya kullanıcının o an için makyaj ve cilt bakım önerisi isteyip istemediğini seçeceği bir buton/switch ekle.
   4. Dinamik AI Açıklamaları ve Prompt Optimizasyonu: AI'ın önerdiği kombinin altında yer alan kombin, cilt bakım ve makyaj açıklamalarını kullanıcının seçimlerine göre optimize et ve çeşitlendir, tekrara düşmesin. Eğer kullanıcı cilt bakım/makyaj önerisi istemediyse AI promptunu bunu dışlayacak şekilde ayarla ve arayüzü bu çeşitliliğe uyumlu, esnek bir yapıya kavuştur.



&#x20;    \[YÜKSEK ÖNCELİKLİLER]

&#x20;  5. Sürükle-bırak planlayıcı: Haftalık ajandada drag \& drop ile gün değiştirme (Hafta 3) 

&#x20;  6. Aynı kıyafet uyarısı: Bu hafta aynı kıyafeti iki gün giyme kontrolü (Hafta 3) 

&#x20;  7. Bildirim ayarları ekranı: Her bildirimi aç/kapat + saat seçimi UI'ı (Hafta 3) 

&#x20;  8. Konfeti animasyonu: Rozet kazanıldığında Lottie konfeti efekti (Hafta 4)



&#x20;    \[ORTA ÖNCELİKLİLER]

&#x20;  9. Gardırop doluluk skoru: Analitik ekranında doluluk \& çeşitlilik metriği (Hafta 3) 

&#x20;  10. Eksik parça önerisi: AI'a gardırop profili gönderip tavsiye alma ekranı (Hafta 3) 

&#x20;  11. Streak (gün serisi) takibi: Günlük giriş sayacı; 7 Gün Serisi rozeti tetikleyicisi (Hafta 4) 

&#x20;  12. Konum izni fallback: İzin reddedilince manuel şehir girişi seçeneği (Hafta 2) 

&#x20;  13. Rozet Galerisi ekranı: Tüm rozetler kilitli/kazanılmış ayrımıyla listelenmeli (Hafta 4)   



Lütfen kuralları okuduğunu onayla ve  doğrudan 1. sıradaki "Kullanıcı Doğum Tarihi ve Burç Entegrasyonu" özelliğini kodlamaya başla.

