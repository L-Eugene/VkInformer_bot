# frozen_string_literal: true

require 'singleton'

# Vk module
module Vk
  # Telegram connection singleton
  class Tlg
    include Singleton

    attr_reader :client

    def initialize
      token = Vk.cfg.options['tg_token']
      @client = Telegram::Bot::Client.new(token)
    end

    def self.escape(text)
      text.gsub('*', '\*').gsub('_', '\_')
    end

    def self.available?
      Vk.tlg.api.get_me['ok']
    rescue StandardError
      Vk.log.error "#{$ERROR_INFO.message}\n#{$ERROR_INFO.backtrace.join("\n")}"
      false
    end
  end

  def self.tlg
    Vk::Tlg.instance.client
  end
end
