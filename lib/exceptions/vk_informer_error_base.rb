# frozen_string_literal: true

module Vk
  # Basic class for exceptions with telegram message support
  class ErrorBase < StandardError
    attr_reader :cmessage

    def initialize(options = {})
      @data = options[:data] if options.key? :data
      @chat = options[:chat] if options.key? :chat
      @cmessage = options[:cmessage] || default_cmessage
      msg = options[:msg] || default_message
      super(msg)
    end

    def process
      Vk.log.__send__(log_level, message)
      Vk.log.__send__(log_level, @data.inspect) unless @data.nil?

      @chat&.send_message(text: cmessage)
    end

    private

    def default_message
      raise Vk.t.classes.undefined
    end

    def default_cmessage
      raise Vk.t.classes.undefined
    end

    def log_level
      :error
    end
  end
end
