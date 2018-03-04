# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Textual message
  class Textual < Attachment
    attr_reader :text

    def initialize(domain, node)
      super
      @text = "#{domain_prefix domain}:\n#{normalize_text(node['text'])}"
    end

    def to_hash
      { text: text }
    end

    def use_method
      :send_message
    end
  end
end
