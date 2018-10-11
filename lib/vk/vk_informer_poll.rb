# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Textual message
  class Poll < Attachment
    attr_reader :text

    def initialize(domain, node)
      super

      @text = <<~TEXT
        #{domain_prefix domain}:
        Poll: #{normalize_text(node[:poll][:question])}
        #{node[:poll][:answers].map { |a| "- #{a[:text]}" }.join("\n")}
      TEXT
    end

    def to_hash
      { text: text }
    end

    def use_method
      :send_message
    end
  end
end
