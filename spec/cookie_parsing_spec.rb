require 'spec_helper'

describe Watobo::Cookie do
  context "Parse Cookie From Set-Cookie Header" do
    cookie_str = 'Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; path=/; secure'
    cookie = Watobo::Cookie.new(cookie_str)

    it "check cookie name" do
      expect(cookie.name).to eq('mycookie')
    end

    it "check cookie value" do
      expect(cookie.value).to eq('b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b')
    end

    it "check cookie location" do
      expect(cookie.location).to eq(:cookie)
    end
  end
end