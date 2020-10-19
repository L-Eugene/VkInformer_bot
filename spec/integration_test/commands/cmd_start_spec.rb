# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe VkInformerBot do
  describe '/start command' do
    before :each do
      @vk = VkInformerBot.new
      @chat = FactoryBot.create(:chat, id: 1, enabled: false)
      allow(@chat).to receive(:send_message) { |msg| msg }
      allow(@vk).to receive(:chat) { @chat }

      Vk::Localization.instance.instance_variable_set(
        :@object,
        R18n.set('en', Vk::Localization.instance.object.translation_places.first.dir)
      )
    end

    it 'should enable disabled chat' do
      expect(@chat.reload.enabled).to be false
      expect(@chat)
        .to receive(:send_message).with(hash_including(text: 'Enabling this chat'))
      expect { @vk.__send__(:cmd_start, []) }.not_to raise_error
      expect(@chat.reload.enabled).to be true
    end

    it 'should not change enabled chat' do
      @chat.update_attribute(:enabled, true)

      expect(@chat.reload.enabled).to be true
      expect(@chat).not_to receive(:send_message)
      expect { @vk.__send__(:cmd_start, []) }.not_to raise_error
      expect(@chat.reload.enabled).to be true
    end
  end
end
