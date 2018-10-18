# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Chat do
  describe 'Basic' do
    before :each do
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

    it 'should split long messages right' do
      expect(@chat.send(:split_message, '123')).to contain_exactly("123\n")

      long_message = 'x' * Vk::Chat::MAX_LENGTH
      expect(@chat.send(:split_message, "#{long_message}\n321")).to contain_exactly("#{long_message}\n", "321\n")

      length = Vk::Chat::MAX_LENGTH * 2 / 400 + 2
      long_message = length.downto(0).each_with_object(+'') do |_i, s|
        s << 'i' * 400 << "\n"
      end
      expect(@chat.send(:split_message, long_message).size).to eq 3
    end
  end

  describe 'Wall list processing' do
    before :each do
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
