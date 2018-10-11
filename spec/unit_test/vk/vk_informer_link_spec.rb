# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Link do
  before(:all) do
    @obj = Vk::Link.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/link/hash.wo_prev.json'
      )
    )

    @obj2 = Vk::Link.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/link/hash.w_prev.json'
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

    it 'should use send_photo API call if preview given' do
      expect(@obj2.use_method).to eq :send_photo
    end
  end

  describe 'Hash build' do
    it 'should build result hash for link without peview' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:text)
      expect(h).to have_key(:disable_web_page_preview)
      expect(h[:disable_web_page_preview]).to be false
    end

    it 'should build result hash for link with peview' do
      h = @obj2.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:type)
      expect(h[:type]).to eq 'photo'
      expect(h).to have_key(:media)
      expect(h).to have_key(:caption)
      expect(h).to have_key(:parse_mode)
    end
  end
end
