require 'spec_helper'
require File.dirname(__FILE__) + '/helpers/cache_spec_helpers'
require 'merb_global/merb-cache/controller'

describe Merb::Cache::CacheMixin do
  before(:all) do
    Merb::Cache.stores.clear
    Thread.current[:'merb-cache'] = nil

    Merb::Cache.register(:dummy_store, DummyStore)
    Merb::Cache.register(:locale_store, Merb::Global::Cache::LocaleStore[:dummy_store])
    Merb::Cache.register(:default, Merb::Cache::PageStore[:locale_store])
    @locale_store = Merb::Cache[:locale_store]
    @page_store   = Merb::Cache[:default]
    @dummy = Merb::Cache[:dummy_store]
  end
  
  describe ".global_eager_cache" do
    before(:each) do
      Object.send(:remove_const, :GlobalEagerCacher) if defined?(GlobalEagerCacher)

      class GlobalEagerCacher < Merb::Controller
        def index
          "index"
        end
      end
    end
    
    describe " should conform to the specifications from .eager_cache" do
      it "should accept a block with an arity of 1" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|params|}
        end
         dispatch_to(GlobalEagerCacher, :index)
        lambda { }.should_not raise_error
      end

      it "should accept a block with an arity greater than 1" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|params, env|}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error
      end

      it "should accept a block with an arity of -1" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|*args|}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error
      end

      it "should accept a block with an arity of 0" do
        class GlobalEagerCacher
          global_eager_cache(:index) {||}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error
      end

      it "should allow the block to return nil" do
        class GlobalEagerCacher
          global_eager_cache(:index) {}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error
      end

      it "should allow the block to return a params hash" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|params| params.merge(:foo => :bar)}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error(ArgumentError)
      end

      it "should allow the block to return a Merb::Request object" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|params| build_request('/')}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error(ArgumentError)
      end

      it "should allow the block to return a Merb::Controller object" do
        class GlobalEagerCacher
          global_eager_cache(:index) {|params, env| GlobalEagerCacher.new(env)}
        end

        lambda { dispatch_to(GlobalEagerCacher, :index) }.should_not raise_error(ArgumentError)
      end
    end
    
    describe " should work with multiples locales" do
      before(:each) do
        Object.send(:remove_const, :GlobalEagerCacher) if defined?(GlobalEagerCacher)
        Merb::Global::Locale.stubs(:supported_locales).returns(['en','pl'])
        
        class GlobalEagerCacher < Merb::Controller
          def index
            _("Hello")
          end
        
          global_eager_cache :create, :index
          
          def create
          end
        end
        @locale_store.delete_all!
      end
      
      it 'should eager_cache and write multiple locales in the data store' do
        lambda { dispatch_to(GlobalEagerCacher, :create) }.should_not raise_error{ArgumentError}

        @dummy.data(@locale_store.send(:normalize, '/index.html', 'en')).should == "Hello"
        @dummy.data(@locale_store.send(:normalize, '/index.html', 'pl')).should == "Cześć"       
        @dummy.exists?(@locale_store.send(:normalize, '/index.html', 'ja')).should be_false
      end
    end
    
  end
end