module Vk
  class Log
    @@log = nil

    def self.logger
      return @@log unless @@log.nil?
      @@log = Logger.new(Vk::Config::get('logfile'), 'daily')
      @@log.level = File.exist?(Vk::Config::get('debug')) ? Logger::DEBUG : Logger::INFO
      @@log.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        if %w[INFO WARN].include? severity
          "[#{date_format}] #{severity}:  #{msg}\n"
        else
          "[#{date_format}] #{severity}: #{msg}\n"
        end
      end
      @@log
    end
  end
end
