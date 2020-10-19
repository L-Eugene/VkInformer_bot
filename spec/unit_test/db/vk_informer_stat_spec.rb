# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Stat do
  before :each do
    @stat = FactoryBot.create(:stat, count: 6)
  end

  it 'should provide needed attributes' do
    expect(@stat).to respond_to(:id, :date, :count, :token)
  end

  it 'should increment usage counter' do
    expect(@stat.count).to eq 6
    @stat.act
    expect(@stat.count).to eq 7
  end
end
