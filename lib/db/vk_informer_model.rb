# frozen_string_literal: true

require 'active_record'

# VK Bot namespace
module Vk
  # Default active record class
  class VkInformerBase < ActiveRecord::Base
    self.abstract_class = true

    establish_connection(Vk::Config.instance.options['database'])
    @logger = Vk::Log.instance.logger
  end

  ActiveSupport::LogSubscriber.colorize_logging = false
end

require 'db/vk_informer_chat.rb'
require 'db/vk_informer_wall.rb'
require 'db/vk_informer_link.rb'
