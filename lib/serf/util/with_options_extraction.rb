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
      return @options || {}
    end

    protected

    ##
    # Helper method to lookup an option from our options hash.
    #
    # Examples:
    #
    #   # Optional parameter whose default value is nil.
    #   do_extra = opts :do_extra
    #
    #   # Optional params that defaults to [1,2,3]
    #   start_array = opts :start_array, [1,2,3]
    #
    # Returns default value when:
    # * Key is non-existent in Options Hash.
    # * OR when the value of the key in the Options Hash is nil.
    #
    # Returns nil when:
    # * Default is nil and the Options Hash lookup returns a nil.
    #   Options Hash returns a nil because of either a
    #   non-existent key or a nil value in said hash for said key.
    #
    def opts(key, default=nil)
      value = options[key]
      value = default if value.nil?
      return value
    end

    ##
    # Use this lookup helper if a nil value is unacceptable for processing.
    #
    # There are cases where an option may have a default value for a feature,
    # but the caller may just want to disable said feature. To do so,
    # users of this module should allow for the caller to pass in 'false'
    # as an option value instead of nil to disable said feature. The
    # implementer will have to do a boolean check of the returned option value
    # and disable accordingly.
    #
    # Examples:
    #
    #   # Has a default logger, but we can disable logging by passing false.
    #   # If caller had passed in nil for :logger, it would have
    #   # defaulted to ::Log4r['my_logger'].
    #   logger = opts! :logger, ::Log4r['my_logger']
    #   logger = Serf::NullObject.new unless logger
    #
    #   # Here we force the end user to pass in a Non-nil option as a
    #   # mandatory parameter.
    #   max_threads = opts! :max_threads
    #
    # Raises error when `opts` returns a nil.
    #
    def opts!(key, default=nil)
      value = opts key, default
      raise "Nil value found for option: #{key}, #{default}" if value.nil?
      return value
    end

    ##
    # Extracts the options from the arguments list.
    #
    def extract_options!(args)
      _, @options = args.last.is_a?(::Hash) ?
        [true, args.pop.dup] :
        [false, {}]
    end

  end

end
end
