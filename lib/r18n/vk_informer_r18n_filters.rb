# frozen_string_literal: true

require 'r18n-core'

R18n::Filters.add('enabled') do |translation, _config, data|
  data[:enabled] ? translation['enabled'] : translation['disabled']
end
