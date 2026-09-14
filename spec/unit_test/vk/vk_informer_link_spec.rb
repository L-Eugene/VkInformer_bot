# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Link do
  def build_link(fixture)
    Vk::Link.new(
      'x',
      load_json_fixtures(
        "#{File.dirname(__FILE__)}/../../fixtures/vk_informer_attachment/link/#{fixture}"
      )
    )
  end

  before :each do
    @download = stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 200, body: 'image')

    @obj = build_link('hash.wo_prev.json')
    @obj2 = build_link('hash.w_prev.json')
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method, :variants)
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
      # Object with big image
      h = @obj2.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:type)
      expect(h[:type]).to eq 'photo'
      expect(h).to have_key(:media)
      expect(h[:media]).to eq 'http://example.com/image.jpg'
      expect(h).to have_key(:caption)
      expect(h).to have_key(:parse_mode)

      # Object without big image
      h = build_link('hash.w_prev.small.json').to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:type)
      expect(h[:type]).to eq 'photo'
      expect(h).to have_key(:media)
      expect(h[:media]).to eq 'http://example.com/image.small.jpg'
    end
  end

  describe 'Variants' do
    it 'should send link without preview as a single text message' do
      expect(@obj.variants).to eq [[:send_message, @obj.to_hash]]
    end

    it 'should fall back from preview URL to upload and then to text' do
      variants = @obj2.variants.to_a
      expect(variants.map(&:first)).to eq %i[send_photo send_photo send_message]
      expect(variants[0].last[:media]).to eq 'http://example.com/image.jpg'
      expect(variants[1].last[:media]).to be_a(Faraday::UploadIO)
      expect(variants[2].last).to have_key(:text)
    end

    it 'should not download preview unless URL was rejected' do
      @obj2.variants.first
      expect(@download).not_to have_been_made
    end
  end
end
