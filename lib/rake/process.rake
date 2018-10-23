# frozen_string_literal: true

namespace :vk do
  desc 'Perform scan'
  task :scan do
    VkInformerBot.new.scan
  end
end
