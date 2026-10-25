# Idempotent demo verisi: her deploy'da güvenle tekrar çalıştırılabilir.
agents = [
  [ "Elif Yılmaz", "elif@talepio.test" ],
  [ "Mert Kaya", "mert@talepio.test" ],
  [ "Zeynep Demir", "zeynep@talepio.test" ]
].map { |name, email| Agent.find_or_create_by!(email: email) { |a| a.name = name } }

return if Ticket.exists?

now = Time.current
samples = [
  { subject: "Faturamda çift çekim görünüyor", priority: "high", opened: 20.minutes.ago },
  { subject: "Şifre sıfırlama e-postası gelmiyor", priority: "normal", opened: 2.hours.ago },
  { subject: "API anahtarımı nasıl yenilerim?", priority: "low", opened: 30.minutes.ago },
  { subject: "Mobil uygulama açılışta çöküyor", priority: "urgent", opened: 3.minutes.ago }
]

samples.each_with_index do |s, i|
  Ticket.create!(
    subject: s[:subject],
    description: "#{s[:subject]}. Yardımcı olabilir misiniz?",
    requester_name: [ "Ayşe Şahin", "Can Öztürk", "Deniz Arslan", "Burak Çelik" ][i],
    requester_email: "musteri#{i + 1}@ornek.test",
    priority: s[:priority],
    created_at: s[:opened],
    updated_at: s[:opened]
  )
end

answered = Ticket.create!(
  subject: "Kullanıcı ekleyemiyorum",
  description: "Yönetici panelinde 'kullanıcı ekle' düğmesi pasif.",
  requester_name: "Selin Koç", requester_email: "selin@ornek.test",
  priority: "normal", created_at: now - 1.day, updated_at: now - 1.day
)
answered.reply_as_agent!(agents.first, "Lisans sayınız dolmuş görünüyor, bir koltuk açtık. Tekrar dener misiniz?",
                         status: "pending", at: now - 1.day + 40.minutes)
