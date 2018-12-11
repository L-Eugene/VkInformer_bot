# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe VkInformerBot do
  describe '/stop command' do
    before :each do
      @vk = VkInformerBot.new
      @chat = FactoryBot.create(:chat, id: 1, enabled: true)
      allow(@chat).to receive(:send_message) { |msg| msg }
      allow(@vk).to receive(:chat) { @chat }
    end

    it 'should disable enabled chat' do
      expect(@chat.reload.enabled).to be true
      expect(@chat)
        .to receive(:send_message).with(hash_including(text: 'Disabling this chat'))
      expect { @vk.__send__(:cmd_stop, []) }.not_to raise_error
      expect(@chat.reload.enabled).to be false
    end

    it 'should not change disabled chat' do
      @chat.update_attribute(:enabled, false)

      expect(@chat.reload.enabled).to be false
      expect(@chat).not_to receive(:send_message)
      expect { @vk.__send__(:cmd_stop, []) }.not_to raise_error
      expect(@chat.reload.enabled).to be false
    end
  end
end
