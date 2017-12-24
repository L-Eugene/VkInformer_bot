# frozen_string_literal: true

module Vk
  # Logger singleton
  class Log
    @@log = nil

    def self.logger
      return @@log unless @@log.nil?
      @@log = Logger.new(Vk::Config.get('logfile'), 'daily')
      @@log.level = File.exist?(Vk::Config.get('debug')) ? Logger::DEBUG : Logger::INFO
      @@log.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity}: #{msg}\n"
      end
      @@log
    end
  end
end
