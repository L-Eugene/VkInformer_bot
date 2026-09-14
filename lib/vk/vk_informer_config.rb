# frozen_string_literal: true

require 'singleton'
require 'yaml'

# VK informer namespace
module Vk
  # Config singleton
  class Config
    include Singleton

    attr_reader :options

    CONFIG_PATH = File.expand_path('../../vk_informer_bot.rb.yml', __dir__)

    def initialize
      @options = YAML.load_file(CONFIG_PATH)
    end
  end

  def self.cfg
    Vk::Config.instance
  end
end
