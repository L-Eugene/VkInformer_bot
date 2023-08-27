#!ruby
# frozen_string_literal: true

require_relative 'vk_informer_bot'
require 'cron_parser'

SCHEDULES = [
  '* 5-16 * * *',
  '*/5 0-3,18-23 * * *'
].map { |defn| CronParser.new defn }

threads = []

# Poll commands
threads << Thread.new do
  VkInformerBot.new.poll
end

# Scheduled scans
threads << Thread.new do
  bot = VkInformerBot.new

  loop do
    bot.scan
    sleep SCHEDULES.map { |cp| (cp.next - Time.now).ceil }.min
  end
end

threads.each(&:join)
