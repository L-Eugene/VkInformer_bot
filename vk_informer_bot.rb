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
require 'r18n/vk_informer_r18n'
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

    process_message(update.message) unless update.message.nil?
    process_callback(update.callback_query) unless update.callback_query.nil?
  rescue Vk::ErrorBase
    $ERROR_INFO.process
  rescue StandardError
    Vk.log_format($ERROR_INFO)
  end

  def scan
    cleanup

    log.info Vk.t.scan.start

    return unless Vk::Tlg.available?

    Vk::Wall.process

    log.info Vk.t.scan.finish
  rescue StandardError
    Vk.log_format($ERROR_INFO)
  end

  private

  def process_callback(callback)
    @chat = Vk::Chat.find_or_create_by(chat_id: callback.message.chat.id)

    data = JSON.parse callback.data, symbolize_names: true

    __send__(data[:meth], data[:args]) if respond_to? data[:meth].to_sym, true
    @chat.send_callback_answer callback, data
  end

  def process_message(message)
    @chat = Vk::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = method_from_message(message.text)
    args = parse_args(%r{^\/[\w@]+\s?}, message.text)

    __send__(meth, args) if respond_to? meth.to_sym, true
  end

  def method_from_message(text)
    meth = (text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    log.info Vk.t.log.command(method: meth, chat: chat.chat_id, text: text)

    "cmd_#{meth}"
  end

  def parse_args(preg, msg)
    msg.gsub(preg, '').gsub(%r{\s+}m, ' ').strip.split(' ')
  end

  def cmd_start(_args)
    unless chat.enabled?
      chat.send_text Vk.t.chat.enable
      chat.walls.each { |wall| wall.update_last unless wall.watched? }
    end

    chat.update_attribute(:enabled, true)
  end

  def cmd_stop(_args)
    chat.send_text Vk.t.chat.disable if chat.enabled?
    chat.update_attribute(:enabled, false)
  end

  def cmd_add(args)
    group = Vk::Wall.find_or_create_by(domain: args.first)
    chat.add group
    log.info Vk.t.log.added(domain: group.domain_escaped, chat: chat.chat_id)
  end

  def cmd_delete(args)
    domain = args.first
    group = Vk::Wall.find_by(domain: domain)
    chat.delete group
    log.info Vk.t.log.deleted(domain: group.domain_escaped, chat: chat.chat_id)
  end

  def cmd_list(_args)
    chat.send_message chat.status, 'HTML'
  end

  def cmd_help(_args)
    chat.send_text Vk.t.help, 'HTML'
  end

  def cleanup
    Vk::Wall.where(last_message_id: nil).delete_all
  end
end
