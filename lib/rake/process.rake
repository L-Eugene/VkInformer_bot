# frozen_string_literal: true

namespace :vk do
  task :scan do
    VkInformerBot.new.scan
  end
end
