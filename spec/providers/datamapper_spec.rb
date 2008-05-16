require 'spec_helper'
require 'data_mapper'

DataMapper::Database.setup :adapter => 'sqlite3', :database => ':memory:'

require 'merb_global/providers/datamapper'

describe Merb::Global::Providers::DataMapper do
  before do
    DataMapper::Persistence.auto_migrate!
    @provider = Merb::Global::Providers::DataMapper.new
  end
  describe '.create!' do
    it 'should call automigrate' do
      lambda {@provider.create!}.should_not raise_error
    end
  end
  describe '.support?' do
    before do
      lang = Merb::Global::Providers::DataMapper::Language
      lang.create! :name => "en", :plural => "n>1?1:0"
    end
    it 'should return true for language in database' do
      @provider.support?('en').should == true
    end
    it 'should return false otherwise' do
      @provider.support?('fr').should == false
    end
  end
  describe '.translate_to' do
    before do
      lang = Merb::Global::Providers::DataMapper::Language
      en = lang.create! :name => "en", :plural => "n>1?1:0"
      trans = Merb::Global::Providers::DataMapper::Translation
      trans.create! :language_id => en.id, :msgid_hash => "Test".hash,
                    :msgstr => "One test", :msgstr_index => 0
      trans.create! :language_id => en.id, :msgid_hash => "Test".hash,
                    :msgstr => "Many tests", :msgstr_index => 1
    end
    it 'should fetch the correct translation from database if avaible' do
      trans = @provider.translate_to("Test", "Tests", :lang => "en", :n => 1)
      trans.should == "One test"
    end
    it 'should fallback to default if needed' do 
      trans = @provider.translate_to("Test", "Tests", :lang => "fr", :n => 2)
      trans.should == "Tests"
    end
  end
end
