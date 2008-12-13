module Merb::Global
  module Cache
    class LocaleStore < Merb::Cache::AbstractStrategyStore
      def writable?(key, parameters = {}, conditions = {})
        case key
        when String, Numeric, Symbol
          @stores.any? {|c| c.writable?(normalize(key), parameters, conditions)}
        else nil
        end
      end

      def read(key, parameters = {})
        @stores.capture_first {|c| c.read(normalize(key), parameters)}
      end

      def write(key, data = nil, parameters = {}, conditions = {})
        if writable?(key, parameters, conditions)
          @stores.capture_first {|c| c.write(normalize(key), data, parameters, conditions)}
        end
      end

      def write_all(key, data = nil, parameters = {}, conditions = {})
        if writable?(key, parameters, conditions)
          @stores.map {|c| c.write_all(normalize(key), data, parameters, conditions)}.all?
        end
      end

      def fetch(key, parameters = {}, conditions = {}, &blk)
        read(key, parameters) || (writable?(key, parameters, conditions) && @stores.capture_first {|c| c.fetch(normalize(key), parameters, conditions, &blk)})
      end

      def exists?(key, parameters = {})
        @stores.capture_first {|c| c.exists?(normalize(key), parameters)}
      end

      def delete(key, parameters = {})
        supported_locales.each do |lang|
          @stores.map {|c| c.delete(normalize(key, lang), parameters)}.any?
        end
      end

      def delete_all!
        @stores.map {|c| c.delete_all! }.all?
      end
    
   private

      def normalize(key, lang = nil)
        (lang || current_locale) / "#{key}"
      end
    
      def current_locale
        Merb::Global::Locale.current.to_s
      end
    
      def supported_locales
        Merb::Global::Locale.supported_locales
      end
    end
  end
end