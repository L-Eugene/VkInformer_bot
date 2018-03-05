# frozen_string_literal: true

namespace :vk do
  namespace :chat do
    desc 'Invert site activation (disable enabled and enable disabled)'
    task :invert do
      Vk::Chat.all.each { |c| c.update_attribute(:enabled, !c.enabled?) }
    end
  end
end
