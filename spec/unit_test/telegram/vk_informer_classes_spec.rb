# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Tlg do
  it 'should escape messages right' do
    expect(Vk::Tlg.escape('domainXsed3')).to eq 'domainXsed3'
    expect(Vk::Tlg.escape('*domain*Xsed3')).to eq '\*domain\*Xsed3'
    expect(Vk::Tlg.escape('_domain_Xsed3')).to eq '\_domain\_Xsed3'
    expect(Vk::Tlg.escape('*_domain_*Xsed3')).to eq '\*\_domain\_\*Xsed3'
  end
end
