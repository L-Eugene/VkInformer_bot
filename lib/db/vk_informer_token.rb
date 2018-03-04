# frozen_string_literal: true

module Vk
  # VK token
  class Token < VkInformerBase
    has_many :stats

    def act
      stats.find_or_create_by(date: Date.today).act
      self
    end
    
    def self.today_stat
      Vk::Token.all.each do |t|
        t.stats.find_or_create_by(date: Date.today)
      end
    end
    
    def self.best
      today_stat
      Vk::Stat.order(:count).find_by(date: Date.today).token.act
    end
  end
end
