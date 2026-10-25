ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # travel_to saati süreç genelinde değiştirdiği için testler thread'lerle paralel koşmaz.
    parallelize(workers: 1)

    include ActiveSupport::Testing::TimeHelpers

    def create_agent(name: "Elif Yılmaz", email: "elif@talepio.test")
      Agent.create!(name: name, email: email)
    end

    def create_ticket(**attrs)
      Ticket.create!({
        subject: "Ödeme sayfası açılmıyor",
        description: "500 hatası alıyorum.",
        requester_name: "Ayşe Şahin",
        requester_email: "ayse@ornek.test",
        priority: "normal"
      }.merge(attrs))
    end
  end
end
