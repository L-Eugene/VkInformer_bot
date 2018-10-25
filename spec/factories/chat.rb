# frozen_string_literal: true

require 'db/vk_informer_chat'

FactoryBot.define do
  factory :chat, class: Vk::Chat do
    chat_id { '-6574354' }
  end
end
