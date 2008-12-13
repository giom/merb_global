require 'spec_helper'
require File.dirname(__FILE__) + '/helpers/abstract_strategy_store'

require 'merb-cache'

describe Merb::Global::Cache::LocaleStore do
  it_should_behave_like 'all strategy stores'

  before(:each) do
    Merb::Global::Locale.stubs(:supported_locales).returns(['en','pl', 'de'])

    @klass = Merb::Global::Cache::LocaleStore
    @store = Merb::Global::Cache::LocaleStore[DummyStore].new
  end

  describe "#writable?" do
    it "should be true if the key is a string, symbol, or number" do
      @store.writable?(:foo).should be_true
      @store.writable?('foo').should be_true
      @store.writable?(123).should be_true
    end

    it "should be false if none of the context caches are writable" do
      @store.stores.each {|s| s.expects(:writable?).returns false}
      @store.writable?(:foo).should be_false
    end
  end

  describe "#read" do
    it "should return nil if if the key does not exist for the current language in any context store" do
      @store.stores.each {|s| s.expects(:read).with(@store.send(:normalize, :foo), :bar => :baz).returns nil}
      @store.read(:foo, :bar => :baz).should be_nil
    end
    
    it "should return the data from the context store when the key matches with the current language" do
      @store.stores.each {|s| s.expects(:read).with(@store.send(:normalize, :foo), :bar => :baz).returns :bar}
      @store.read(:foo, :bar => :baz).should == :bar
    end 
  end

  describe "#write" do
    it "should pass the key together with the locale to the context store" do
      @store.stores.first.expects(:write).with(@store.send(:normalize, :foo), 'body', {}, {}).returns true
    
      @store.write(:foo, 'body').should be_true
    end
  end
  
  describe "#delete" do
    it "should delete all locales for the key" do
      Merb::Global::Locale.supported_locales.each do |loc|
        @store.stores.first.expects(:delete).with(@store.send(:normalize, :foo, loc), {:bar => :baz})
      end
      
      @store.delete(:foo, {:bar => :baz})
    end
  end
  
  describe "private methods" do
  
    describe "#current_locale" do
      it "should return the current Merb::Global locale" do
        @store.send(:current_locale).should == Merb::Global::Locale.current.to_s
      end
    end
  
    describe "#supported_locales" do
      it "should return the list of supported locales" do
        @store.send(:supported_locales).should == Merb::Global::Locale.supported_locales
      end
    end
  
    describe "#normalize" do
      it "should include the locale with the key" do
        current_locale = @store.send(:current_locale)
        @store.send(:normalize, :foo).should == current_locale / "foo"
      end
    
      it "should accept a locale as optional parameter and include it with the key" do
        @store.send(:normalize, :foo, 'en').should == 'en' / "foo"
      end
    end

  end
end