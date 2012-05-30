require 'serf/util/options_extraction'

module Serf
module Routing

  ##
  # A matcher that does a regexp match on a specific field
  # in the given Env. By default, we use this to do regexp matching
  # on message kinds for routing.
  #
  class RegexpMatcher
    include Serf::Util::OptionsExtraction

    attr_reader :regexp
    attr_reader :field

    def initialize(regexp, *args)
      extract_options! args

      @regexp = regexp
      @field = opts :field, :kind
    end

    def ===(env)
      return regexp === env[field]
    end

    def self.build(*args, &block)
      new *args, &block
    end

  end

end
end
