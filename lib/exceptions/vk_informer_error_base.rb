# frozen_string_literal: true

module Vk
  # Basic class for exceptions with telegram message support
  class ErrorBase < StandardError
    include R18n::Helpers

    attr_reader :cmessage

    def initialize(options = {})
      @data = options[:data] if options.key? :data
      @chat = options[:chat] if options.key? :chat
      @cmessage = options[:cmessage] || default_cmessage
      msg = options[:msg] || default_message
      super(msg)
    end

    def process
      Vk.log.send(log_level, message)
      Vk.log.send(log_level, @data.inspect) unless @data.nil?

      @chat&.send_message(text: cmessage)
    end

    private

    def default_message
      raise t.classes.undefined
    end

    def default_cmessage
      raise t.classes.undefined
    end

    def log_level
      :error
    end
  end
end
