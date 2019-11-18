# frozen_string_literal: true

require 'singleton'

# Vk module
module Vk
  # Logger singleton
  class Log
    include Singleton

    attr_reader :logger
    attr_accessor :last_reopen

    def initialize
      flag = Vk.cfg.options['debug']['flag']

      @logger = Logger.new(Vk.cfg.options['logfile'])
      @logger.level = Logger::INFO
      @logger.level = Logger::DEBUG if File.exist?(flag) || Vk.cfg.options['debug']['default']
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity}: #{msg}\n"
      end

      @last_reopen = Time.now
    end
  end

  def self.log_format(error_info, type = :error)
    log.__send__(type, "#{error_info.message}\n#{error_info.backtrace.join("\n")}")
  end

  def self.log
    Vk::Log.instance.logger.reopen if Vk::Log.instance.last_reopen < Time.now - 1.hour
    Vk::Log.instance.logger
  end
end
