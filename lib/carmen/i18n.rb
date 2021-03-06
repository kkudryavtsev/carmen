require 'yaml'
require 'pp'

module Carmen
  module I18n

    DEFAULT_LOCALE = 'en'

    # A simple object to handle I18n translation in simple situations.
    class Simple

      attr_accessor :cache
      attr_reader :locale
      attr_reader :locale_paths

      def initialize(*locale_paths)
        @locale = DEFAULT_LOCALE
        @locale_paths = locale_paths.flatten
        @cache = nil
      end

      def append_locale_path(path)
        reset!
        @locale_paths << path
      end

      # Set a new locale
      #
      # Calling this method will clear the cache.
      def locale=(locale)
        reset!
        @locale = locale.to_s
      end

      # Retrieve a translation for a key in the following format: 'a.b.c'
      def t(key)
        read(key.to_s)
      end

      # Clear the cache. Should be called after appending a new locale path
      # manually (in case lookups have already occurred.)
      #
      # When adding a locale path, it's best to use #append_locale_path, which
      # resets the cache automatically.
      def reset!
        @cache = nil
      end

    private

      def read(key)
        load_cache_if_needed
        source = @cache[@locale]
        key.split('.').inject(source) { |hash, key|
          hash[key] unless hash.nil?
        }
      end

      # Load all files located at the @locale_path, merge them, and store the
      # result in @cache.
      def load_cache_if_needed
        return unless @cache.nil?
        hashes = load_hashes_for_paths(@locale_paths)
        @cache = deep_hash_merge(hashes)
      end

      def load_hashes_for_paths(paths)
        paths.collect { |path|
          if !File.exist?(path)
             fail "Path #{path} not found when loading locale files"
          end
          Dir[path + '/**/*.yml'].map { |file_path|
            YAML.load_file(file_path)
          }
        }.flatten
      end

      # Merge an array of hashes deeply. When a conflict occurs, if either the
      # old value or the new value don't respond_to? :merge, the new value is
      # used.
      def deep_hash_merge(hashes)
        return hashes.first if hashes.size == 1

        hashes.inject { |acc, hash|
          acc.merge(hash) { |key, old_value, new_value|
            if old_value.respond_to?(:merge) && new_value.respond_to?(:merge)
              deep_hash_merge([old_value, new_value])
            else
              new_value
            end
          }
        }
      end
    end

  end
end
