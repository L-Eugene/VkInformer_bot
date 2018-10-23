# frozen_string_literal: true

require 'singleton'
require 'English'
require 'telegram/bot'
require 'faraday'
require 'json'
require 'yaml'

# VK informer module
module Vk
  # Config singleton
  class Config
    include Singleton

    attr_reader :options

    CONFIG_PATH = "#{__FILE__}.yml"

    def initialize
      @options = YAML.load_file(CONFIG_PATH)
    end
  end

  def self.cfg
    Vk::Config.instance
  end
end

$LOAD_PATH.unshift(
  File.join(File.dirname(__FILE__), Vk.cfg.options['libdir']),
  File.join(File.dirname(__FILE__), Vk.cfg.options['basedir'])
)

require 'log/vk_informer_logger'
require 'telegram/vk_informer_classes'
require 'db/vk_informer_model'
Dir['vk/*.rb'].each { |f| require f }

# Main bot class
class VkInformerBot
  attr_reader :token, :client, :log, :chat

  def initialize
    @client = Vk.tlg
    @log    = Vk.log
  end

  def update(data)
    update = Telegram::Bot::Types::Update.new(data)
    message = update.message

    process_message(message) unless message.nil?
  rescue Vk::ErrorBase
    $ERROR_INFO.process
  rescue StandardError
    Vk.log.error "#{$ERROR_INFO.message}\n#{$ERROR_INFO.backtrace.join("\n")}"
  end

  def scan
    log.info 'Starting scan'

    Vk::Wall.find_each do |wall|
      run = wall.watched?
      wall.process if run
      wall.update_last unless run
    end

    log.info 'Finish scan'

    cleanup
  end

  private

  HELP_MESSAGE = <<~TEXT
    <strong>/help</strong>  - Print this help message.
    <strong>/start</strong> - Start watching.
    <strong>/stop</strong>  - Pause watching (list of watched groups are not deleted).
    <strong>/add</strong> <em>domain</em> - Add group to watch list. <em>Domain</em> is human-readable group identifier.
    <strong>/delete</strong> <em>domain</em> - Delete group from watch list. <em>Domain</em> is the same as in <strong>/add</strong> command.
    <strong>/list</strong> - Show the list of watched groups.
  TEXT

  def process_message(message)
    @chat = Vk::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = method_from_message(message.text)
    args = parse_args(%r{^\/\w+\s?}, message.text)

    send(meth, args) if respond_to? meth.to_sym, true
  end

  def method_from_message(text)
    meth = (text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    log.info "#{meth} command from #{chat.chat_id}"
    log.debug "Full command is #{text}"

    "cmd_#{meth}"
  end

  def parse_args(preg, msg)
    msg.gsub(preg, '').gsub(%r{\s+}m, ' ').strip.split(' ')
  end

  def cmd_start(_msg, _args)
    chat.send_text 'Enabling this chat' unless chat.enabled?
    chat.update_attribute(:enabled, true)
  end

  def cmd_stop(_msg, _args)
    chat.send_text 'Disabling this chat' if chat.enabled?
    chat.update_attribute(:enabled, false)
  end

  def cmd_add(_msg, args)
    group = Vk::Wall.find_or_create_by(domain: args.first)
    chat.add group
    gdomain = Vk::Tlg.escape(group.domain)
    log.info "Added http://vk.com/#{gdomain} to chat:#{chat.chat_id}."
    chat.send_text "Added http://vk.com/#{gdomain} to your watchlist"
  end

  def cmd_delete(_msg, args)
    domain = args.first
    group = Vk::Wall.find_by(domain: domain)
    chat.delete group
    gdomain = Vk::Tlg.escape domain
    chat.send_text "Removed http://vk.com/#{gdomain} from watchlist"
  end

  def cmd_list(_msg, _args)
    chat.send_text chat.status, 'HTML'
  end

  def cmd_help(_msg, _args)
    chat.send_text HELP_MESSAGE, 'HTML'
  end

  def cleanup
    Vk::Wall.where(last_message_id: nil).delete_all
  end
end
