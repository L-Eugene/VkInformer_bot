# frozen_string_literal: true

module Vk
  # Links between chats and groups
  class Cwlink < VkInformerBase
    belongs_to :wall
    belongs_to :chat

    self.table_name = 'links'
  end
end
