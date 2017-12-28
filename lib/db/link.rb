# frozen_string_literal: true

module Vk
  # Links between chats and groups
  class Link < VkInformerBase
    belongs_to :wall
    belongs_to :chat
  end
end
