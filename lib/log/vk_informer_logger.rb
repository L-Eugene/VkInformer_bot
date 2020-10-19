# frozen_string_literal: true

require 'singleton'

# Vk module
module Vk
  # Logger singleton
  class Log
    include Singleton

    attr_reader :logger

    def initialize
      flag = Vk.cfg.options['debug']['flag']

      @logger = Logger.new(Vk.cfg.options['logfile'])
      @logger.level = Logger::INFO
      @logger.level = Logger::DEBUG if File.exist?(flag) || Vk.cfg.options['debug']['default']
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
    end
  end

  def self.log_format(error_info, type = :error)
    log.__send__(type, "#{error_info.message}\n#{error_info.backtrace.join("\n")}")
  end

  def self.log
    Vk::Log.instance.logger
  end
end
