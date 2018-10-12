# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Poll do
  before :all do
    @obj = Vk::Poll.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/poll/hash.json'
      )
    )
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method)
    end

    it 'should use send_message API call if no preview given' do
      expect(@obj.use_method).to eq :send_message
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      h = @obj.to_hash

      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:text)
    end
  end
end
