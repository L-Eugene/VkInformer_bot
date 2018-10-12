# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Doc do
  before :each do
    @obj = Vk::Doc.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/doc/hash.simple.json'
      )
    )

    @obj2 = Vk::Doc.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/doc/hash.gif.json'
      )
    )
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method)
    end

    it 'should use send_message API call if file is not gif' do
      expect(@obj.use_method).to eq :send_message
    end

    it 'should use send_doc API call if file is gif' do
      expect(@obj2.use_method).to eq :send_doc
    end
  end

  describe 'Hash build' do
    before :each do
      stub_request(:get, 'http://example.com/file.gif')
        .to_return(status: 200, body: '', headers: {})
    end

    it 'should build result hash for doc if file is not gif' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:text)
      expect(h).to have_key(:disable_web_page_preview)
      expect(h[:disable_web_page_preview]).to be false
    end

    it 'should build result hash for link with peview' do
      h = @obj2.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:document)
      expect(h).to have_key(:caption)
      expect(h).to have_key(:parse_mode)
    end
  end
end
