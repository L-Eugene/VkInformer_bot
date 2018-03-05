# frozen_string_literal: true

require 'colorize'

namespace :vk do
  namespace :debug do
    desc 'Enable debug for VkInformer'
    task :on do
      FileUtils.touch Vk.cfg.options['debug']
      puts 'Debug is on'.green
    end

    desc 'Disable debug for VkInformer'
    task :off do
      FileUtils.rm Vk.cfg.options['debug'], force: true
      puts 'Debug is off'.green
    end
  end
end
