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
  end

  def self.tlg
    Vk::Tlg.instance.client
  end
end
