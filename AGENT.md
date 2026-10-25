# AGENT.md: Talepio'da çalışan kodlama ajanları için

Bu dosya, bu repoda çalışacak bir kodlama ajanının (ve insanın) uyması gereken kuralları içerir. Proje sahibi ile Claude Code bu dosyayı projeyi geliştirirken birlikte yazdı. Her maddenin arkasında bu projede gerçekten yaşanmış bir sorun ya da verilmiş bir karar var.

## Ürün tek paragrafta
Talepio, Zendesk Support'tan ilham alan bir destek masası. Aort dilimi şu: müşteri talep açar → temsilci üstlenir ve yanıtlar → beklemeye alır ya da çözer → çözülmüş talep 4 gün sonra kapanır. Ürünü farklı kılan şey **SLA Radarı**: SLA riskini saatlik değil dakikalık hassasiyetle yakalar.

## Değişmez kurallar
1. **Orijinal marka uygulamada görünmez.** "Zendesk" kelimesi ve logosu `app/`, `public/`, `config/` altında geçmez; sadece README'de ilham kaynağı olarak anılır. Kontrol: `git grep -i zendesk -- app public config` boş dönmeli.
2. **İş kurallarının tek kaynağı modellerdir.** Controller'a ya da view'a kural yazılmaz.
   - Durum akışı: `Ticket::TRANSITIONS`. Geçişler yalnızca `transition_to!`, `reply_as_agent!` ve `reply_as_requester!` üzerinden yapılır; `update(status:)` kullanılmaz.
   - SLA süreleri ve son tarih: `SlaPolicy`. Son tarih talep açılırken bir kez hesaplanıp `first_response_due_at` alanına yazılır.
   - Otomatik kapanış: `Ticket::AUTO_CLOSE_AFTER` ve `Ticket.auto_close_solved!`.
   - Radar (uyarı, ihlal, otomatik atama, kapanış): `SlaRadar.sweep!`.
3. **Zamana bağlı her mantık bir `now` parametresi alır** (varsayılanı `Time.current`). Testlerde `travel_to` kullanılır, `sleep` ya da elle saat hesabı kullanılmaz.
4. **Arayüz Türkçedir.** Kullanıcıya görünen metinler Türkçe, sınıf ve metot adları İngilizce. Durum, öncelik ve SLA etiketleri `ApplicationHelper`'daki sözlüklerden gelir.
5. **Ödeme ya da gerçek kişisel veri toplanmaz.** Seed ve demo verilerinde `*.test` alan adları kullanılır.

## Komutlar
| İş | Komut |
|---|---|
| Testler | `bin/rails db:test:prepare test` |
| Stil | `bin/rubocop` (düzeltmek için `-a`) |
| Güvenlik | `bin/brakeman --no-pager` · `bin/bundler-audit` |
| Radarı elle tarama | `bin/rails sla:sweep` |
| Yerelde sunucu | `bin/rails db:prepare db:seed && bin/rails server` |

Windows'ta çalışıyorsan `bin/*` betiklerini `ruby bin/rails ...` diye çağır. Betiklerin shebang'i `ruby` olmalı, `ruby.exe` değil; aksi halde CI ve Docker bozulur. `.gitattributes` dosyası `bin/*` için LF satır sonu zorlar, git'te de çalıştırma izni (`100755`) olmalı.

## "Bitti" demeden önce
Ajan "yaptım" dediğinde bu liste kontrol edilmeden iş bitmiş sayılmaz:
- [ ] `bin/rails test` yeşil, **çıktısı gerçekten okundu**. Test raporu uydurulmaz ya da tahmin edilmez.
- [ ] Yeni ya da değişen bir kuralın en az bir testi var. Zaman kuralıysa test `travel_to` kullanıyor ve sınırın iki tarafını da (bir saniye/dakika önce ve sonra) deniyor.
- [ ] Testin gerçekten bir şey yakaladığı denendi: kural geçici olarak bozuldu, test kırmızı oldu, sonra kural geri alındı. Bu projede `AUTO_CLOSE_AFTER` ve acil SLA süresi bozulduğunda 7 test kırıldı.
- [ ] `bin/rubocop` ve `bin/brakeman` temiz.
- [ ] Arayüz değiştiyse tarayıcıda gerçekten tıklandı (talep aç → giriş → yanıt → çöz).
- [ ] Yapılamayan bir şey varsa README'deki **"Yapamadıklarım"** bölümüne yazıldı. Eksik saklanmaz.

## Sık değişiklik tarifleri
- **SLA hafta sonunu saymasın / mesai saati:** `SlaPolicy.due_at` metodunu değiştir (gerekirse `warning_window` da). `Ticket#sla_state` kayıtlı son tarihi okuduğu için oraya dokunmaya gerek yok. Testi `test/models/ticket_time_rules_test.rb` dosyasına Cuma 17:00 → Pazartesi gibi bir senaryoyla ekle.
- **Yeni bir durum** (ör. `on_hold`): `TRANSITIONS`'a ekle, `ApplicationHelper::STATUS_LABELS`'a ekle, CSS'te `.status-on_hold` rozetini tanımla. SLA'yı durdurup durdurmayacağına karar ver (`ACTIVE_STATUSES`), sonra geçiş testlerini güncelle.
- **Otomatik kapanış süresi:** `Ticket::AUTO_CLOSE_AFTER`. Müşteri portalındaki metin bu sabiti okuduğu için kendiliğinden güncellenir.

## Mimari notlar
- Kuyruk Stimulus `auto-refresh` ile 30 saniyede bir Turbo morph yeniler. Her temsilci isteğinde `SlaRadar.sweep!` çalışır. Render'da `SLA_RADAR_TICKER=1` ile sunucu içinde dakikalık bir thread daha çalışır (yalnızca `rails server` altında).
- `sla_events` tablosunda `(ticket_id, kind)` benzersizdir; bu sayede aynı uyarı iki kez üretilmez.
- Production'da Solid Queue, Cache ve Cable kullanılmıyor; tek bir PostgreSQL var. Bu, Render'ın ücretsiz planı için bilinçli olarak yapılan bir sadeleştirme.
