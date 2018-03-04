# frozen_string_literal: true

module Vk
  # VK token statistic
  class Stat < VkInformerBase
    belongs_to :token
    after_initialize :init

    def act
      update_attribute(:count, count + 1)
    end

    private

    def init
      self.count ||= 0
    end
  end
end
