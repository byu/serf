module Serf
module Util

  ##
  # Module that provides helpers for dealing with options hash passed
  # to initializers.
  #
  #   class Example
  #     include Serf::Util::WithOptionsExtraction
  #
  #     def initialize(*args, &block)
  #       extract_options! args
  #       puts args # Rest of args w/o the options hash.
  #     end
  #
  #     def do_work
  #       my_option = opts :my_option, 'Default Value'
  #       puts my_option
  #     end
  #   end
  #
  #   example = Example.new my_option: 'Another Value'
  #   example.do_work
  #   # => 'Another Value'
  #
  module WithOptionsExtraction

    ##
    # Reader method for the options hash.
    #
    def options
      return @options
    end

    protected

    ##
    # Helper method to get an option from the @options hash.
    #
    def opts(key, default=nil)
      if default.nil?
        return @options.fetch key
      else
        return @options.fetch(key) { default }
      end
    end

    ##
    # Extracts the options from the arguments list.
    #
    def extract_options!(args)
      @options = args.last.is_a?(::Hash) ? args.pop : {}
    end

  end

end
end
