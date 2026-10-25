# İlk yanıt SLA'sının tek kaynağı: önceliğe göre hedef süre ve "riskte" eşiği.
# Hafta sonu / mesai saati gibi bir kural eklenecekse dokunulacak yer due_at'tir.
class SlaPolicy
  FIRST_RESPONSE_TARGETS = {
    "urgent" => 15.minutes,
    "high"   => 1.hour,
    "normal" => 4.hours,
    "low"    => 8.hours
  }.freeze

  # Hedef sürenin son %25'i (en az 5 dakika) "riskte" sayılır.
  WARNING_RATIO = 0.25
  MIN_WARNING_WINDOW = 5.minutes

  def self.target_for(priority)
    FIRST_RESPONSE_TARGETS.fetch(priority)
  end

  # ZAMAN KURALI: ilk yanıtın son tarihi = talebin açıldığı an + öncelik hedefi.
  def self.due_at(priority, from:)
    from + target_for(priority)
  end

  def self.warning_window(priority)
    [ target_for(priority) * WARNING_RATIO, MIN_WARNING_WINDOW ].max
  end
end
