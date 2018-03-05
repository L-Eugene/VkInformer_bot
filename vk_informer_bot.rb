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

    return if message.nil?

    @chat = Vk::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = method_from_message(message.text)

    send(meth, message.text) if respond_to? meth.to_sym, true
  end

  def scan
    log.info 'Starting scan'

    Vk::Wall.find_each do |wall|
      run = wall.watched?
      wall.process if run
      wall.update_last unless run
    end

    log.info 'Finish scan'
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

  def method_from_message(text)
    meth = (text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    log.info "#{meth} command from #{chat.chat_id}"
    log.debug "Full command is #{text}"

    "cmd_#{meth}"
  end

  def cmd_start(_msg)
    chat.send_text 'Enabling this chat' unless chat.enabled?
    chat.update_attribute(:enabled, true)
  end

  def cmd_stop(_msg)
    chat.send_text 'Disabling this chat' if chat.enabled?
    chat.update_attribute(:enabled, false)
  end

  def cmd_add(msg)
    group = Vk::Wall.find_or_create_by(domain: msg.sub(%r{/add\s*}, ''))
    do_add group
  rescue StandardError
    log.error "Cannot add #{group.domain}. Error: #{$ERROR_INFO}"
    chat.send_text $ERROR_INFO.to_chat if $ERROR_INFO.respond_to? 'to_chat'
  ensure
    Vk::Wall.where(last_message_id: nil).delete_all
  end

  def cmd_delete(msg)
    domain = msg.sub(%r{/delete\s*}, '')
    group = Vk::Wall.find_by(domain: domain)
    chat.delete group
  rescue StandardError => error
    log.error "Cannot remove #{domain}. Error: #{error}"
    chat.send_text(error.to_chat) if error.respond_to? 'to_chat'
  else
    chat.send_text "Removed http://vk.com/#{domain} from watchlist"
  end

  def cmd_list(_msg)
    chat.send_text chat.status, 'HTML'
  end

  def cmd_help(_msg)
    chat.send_text HELP_MESSAGE, 'HTML'
  end

  def do_add(group)
    chat.add group
    log.info "Added http://vk.com/#{group.domain} to chat:#{chat.chat_id}."
    chat.send_text "Added http://vk.com/#{group.domain} to your watchlist"
  end
end
