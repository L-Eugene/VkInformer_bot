# frozen_string_literal: true

require 'singleton'

module Vk
  # Logger singleton
  class Log
    include Singleton

    attr_reader :logger

    def initialize
      @logger = Logger.new(Vk::Config.instance.options['logfile'], 'daily')
      @logger.level = File.exist?(Vk::Config.instance.options['debug']) ? Logger::DEBUG : Logger::INFO
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity}: #{msg}\n"
      end
    end
  end
end
