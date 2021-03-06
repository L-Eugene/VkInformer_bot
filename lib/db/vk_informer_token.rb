# frozen_string_literal: true

module Vk
  # VK token
  class Token < VkInformerBase
    has_many :stats, dependent: :destroy

    def act
      stats.find_or_create_by(date: Date.today).act
      self
    end

    def today
      stats.find_or_create_by(date: Date.today).count
    end

    def self.today_stat
      Vk::Token.all.each do |token|
        token.stats.find_or_create_by(date: Date.today)
      end
    end

    def self.best
      today_stat
      result = Vk::Stat.order(:count).find_by(date: Date.today).token.act
      Vk.log.info Vk.t.token.select(id: result.id)
      result
    end
  end
end
