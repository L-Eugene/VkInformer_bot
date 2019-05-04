# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Textual do
  before :all do
    @obj = Vk::Textual.new(
        'x',
        load_json_fixtures(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/text/hash.json'
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

  describe 'Domain prefix and text normalization' do
    it 'should normalize text' do
      expect(@obj.normalize_text('so.me_*doma<i>n')).to eq 'so.me\_\*doman'
    end

    it 'shoul build valid domain prefixes' do
      expect(@obj.domain_prefix('so.me_*doma<i>n', :plain))
        .to eq 'https://vk.com/so.me_*doma<i>n #so_me_*doma<i>n'

      expect(@obj.domain_prefix('so.me_*doma<i>n', :markdown))
        .to eq '[so.me_*doma<i>n](https://vk.com/so.me_*doma<i>n) #so\_me\_\*doman'

      expect(@obj.domain_prefix('so.me_*doma<i>n', :html))
        .to eq '<a href=\'https://vk.com/so.me_*doma<i>n\'>so.me_*doma<i>n</a> #so_me_*doma<i>n'
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      expect(@obj.to_hash).to be_instance_of(Hash)
      expect(@obj.to_hash).to have_key(:text)
      expect(@obj.to_hash[:text]).to eq "[x](https://vk.com/x) #x:\nresult text data"
    end
  end
end
