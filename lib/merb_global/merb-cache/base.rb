module Merb::Global
  module Cache
    autoload :LocaleStore, File.dirname(__FILE__) / 'locale_store'
  end
end

Merb::BootLoader.before_app_loads do
  # This should only be loaded if merb-cache is used
  if defined? Merb::Cache
    require File.dirname(__FILE__) / 'controller'
  end
end