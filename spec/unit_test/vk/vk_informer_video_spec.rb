# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Video do
  before :all do
    @obj = Vk::Video.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/video/hash.json'
      )
    )
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method)
    end

    it 'should use send_message API call' do
      expect(@obj.use_method).to eq :send_message
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:text)

      expect(h).to have_key(:disable_web_page_preview)
      expect(h[:disable_web_page_preview]).to be false

      expect(h).to have_key(:parse_mode)
      expect(h[:parse_mode]).to eq 'HTML'
    end
  end
end
