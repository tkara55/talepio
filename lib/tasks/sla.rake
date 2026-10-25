namespace :sla do
  desc "SLA radarını bir kez tara (cron için): uyarı, ihlal ve otomatik kapanış"
  task sweep: :environment do
    result = SlaRadar.sweep!
    puts "uyarı=#{result.warnings} ihlal=#{result.breaches} kapanan=#{result.closed}"
  end
end
