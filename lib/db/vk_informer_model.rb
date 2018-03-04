# frozen_string_literal: true

require 'active_record'
require 'log/vk_informer_logger'

# VK Bot namespace
module Vk
  # Default active record class
  class VkInformerBase < ActiveRecord::Base
    self.abstract_class = true

    establish_connection(Vk::Config.instance.options['database'])
    @logger = Vk.log
  end

  ActiveSupport::LogSubscriber.colorize_logging = false
end

require 'db/vk_informer_chat'
require 'db/vk_informer_wall'
require 'db/vk_informer_link'
