# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Cwlink do
  it 'should provide needed attributes' do
    link = Vk::Cwlink.new

    expect(link).to respond_to(:id, :chat, :wall)
  end
end
