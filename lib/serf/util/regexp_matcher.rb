module Serf
module Util

  ##
  # A matcher that does a regexp match on a specific field
  # in the given Env. By default, we use this to do regexp matching
  # on message kinds for routing.
  #
  class RegexpMatcher
    attr_reader :regexp
    attr_reader :field

    def initialize(regexp, options={})
      @regexp = regexp
      @field = options.fetch(:field) { :kind }
    end

    def ===(env)
      return @regexp === env[@field]
    end

    def self.build(regexp)
      return self.new regexp
    end

  end

end
end
