# Web sunucusu içinde dakikada bir SLA radarını tarayan hafif bir zamanlayıcı.
# Render'da SLA_RADAR_TICKER=1 ile açılır; yalnızca `bin/rails server` altında çalışır,
# testlerde, konsolda ve rake görevlerinde (db:migrate vb.) başlamaz.
if ENV["SLA_RADAR_TICKER"] == "1" && defined?(Rails::Server)
  Rails.application.config.after_initialize do
    Thread.new do
      loop do
        sleep 60
        begin
          result = Rails.application.executor.wrap { SlaRadar.sweep! }
          Rails.logger.info("[SlaRadar] #{result.to_h}") if result.to_h.values.any?(&:positive?)
        rescue => e
          Rails.logger.error("[SlaRadar] #{e.class}: #{e.message}")
        end
      end
    end
  end
end
