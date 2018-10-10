# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Chat do
  describe 'Basic' do
    before(:each) do
      @chat = FactoryBot.create(:chat)
    end

    it 'should provide needed attributes' do
      # Database fields
      expect(@chat).to respond_to(:id, :chat_id, :enabled)

      # Relations
      expect(@chat).to respond_to(:cwlinks, :walls)
    end

    it 'should enable chat by default' do
      expect(@chat.enabled?).to be true
    end
  end

  describe 'Wall list processing' do
    before(:each) do
      @chat = FactoryBot.create(:chat)
    end

    it 'should add walls' do
      expect(@chat.walls.size).to eq 0

      wall = FactoryBot.create(:wall, id: 1, domain: 'wall1')
      allow(wall).to receive(:correct?) { true }
      @chat.add(wall)

      expect(@chat.walls.size).to eq 1
    end

    it 'should detect if maximal wall count reached' do
      expect do
        1.upto(Vk::Chat::WATCH_LIMIT + 1) do |x|
          wall = FactoryBot.create(:wall, id: x, domain: "wall#{x}")
          allow(wall).to receive(:correct?) { true }
          @chat.add(wall)
        end
      end.to raise_error(Vk::TooMuchGroups)
    end

    it 'should not add one wall twice' do
      wall = FactoryBot.create(:wall, id: 1, domain: 'wall1')
      allow(wall).to receive(:correct?) { true }
      @chat.add(wall)

      expect { @chat.add(wall) }.to raise_error(Vk::AlreadyWatching)
      expect(@chat.walls.size).to eq 1
    end
  end
end
