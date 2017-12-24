# frozen_string_literal: true

require 'English'
require 'telegram/bot'
require 'faraday'
require 'json'
require 'yaml'

module Vk
  # Config singleton
  class Config
    @@options = nil

    def self.conf_path
      "#{__FILE__}.yml"
    end

    def self.options
      return @@options unless @@options.nil?
      @@options = YAML.load_file(conf_path)
    end

    def self.get(option)
      options[option]
    end
  end
end

$LOAD_PATH.unshift(
  File.join(File.dirname(__FILE__), Vk::Config.get('libdir')),
  File.join(File.dirname(__FILE__), Vk::Config.get('basedir'))
)

require 'log/logger'
require 'db/model'
require 'vk/classes'
require 'vk/exceptions'

# Main bot class
class VkInformerTestBot
  attr_reader :token, :client, :log, :chat

  def initialize
    @token  = Vk::Config.get('tg_token')
    @client = Telegram::Bot::Client.new(@token)
    @log    = Vk::Log.logger
  end

  def update(data)
    update = Telegram::Bot::Types::Update.new(data)
    message = update.message

    return if message.nil?

    @chat = Vk::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = (message.text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }
    meth = "cmd_#{meth}"
    send(meth, message.text) if respond_to? meth.to_sym, true
  end

  def scan
    return if scanning?
    scan_flag

    Vk::Wall.find_each do |wall|
      next unless wall.watched?

      wall.process
    end

    scan_unflag
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

  def scanning?
    result = File.exist? Vk::Config.get('flag')
    log.info 'Previous scan is not finished yet.' if result
    result
  end

  def scan_flag
    log.info 'Starting scan'
    FileUtils.touch Vk::Config.get('flag')
  end

  def scan_unflag
    FileUtils.rm Vk::Config.get('flag')
    log.info 'Finish scan'
  end

  def cmd_start(_msg)
    chat.send_message 'Enabling this chat' unless chat.enabled?
    chat.update_attribute(:enabled, true)
  end

  def cmd_stop(_msg)
    chat.send_message 'Disabling this chat' if chat.enabled?
    chat.update_attribute(:enabled, false)
  end

  def cmd_add(msg)
    group = Vk::Wall.find_or_create_by(domain: msg.sub(%r{/add\s*}, ''))
    chat.add group
  rescue StandardError
    log.error "Cannot add #{group.domain}. Error: #{$ERROR_INFO}"
    chat.send_message($ERROR_INFO.to_chat) if $ERROR_INFO.respond_to? 'to_chat'
  else
    log.info "Added http://vk.com/#{group.domain} to chat:#{chat.chat_id}."
    chat.send_message "Added http://vk.com/#{group.domain} to your watchlist"
  ensure
    Vk::Wall.where(last_message_id: nil).delete_all
  end

  def cmd_delete(msg)
    domain = msg.sub(%r{/delete\s*}, '')
    group = Vk::Wall.find_by(domain: domain)
    chat.delete group
  rescue StandardError => error
    log.error "Cannot remove #{domain}. Error: #{error}"
    chat.send_message(error.to_chat) if error.respond_to? 'to_chat'
  else
    chat.send_message "Removed http://vk.com/#{domain} from watchlist"
  end

  def cmd_list(_msg)
    chat.send_message chat.status, 'HTML'
  end

  def cmd_help(_msg)
    chat.send_message HELP_MESSAGE, 'HTML'
  end
end
