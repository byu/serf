require 'serf/util/regexp_matcher'

module Serf
module Routing

  ##
  # EndpointRegistry returns list of Endpoints to execute that match
  # criteria based on the Endpoints' associated 'matcher' object
  # with the input of the ENV Hash (passed to match).
  #
  class Registry

    def initialize(options={})
      @endpoints = {}
      @matchers = []
      @regexp_matcher_factory = options.fetch(:regexp_matcher_factory) {
        ::Serf::Util::RegexpMatcher
      }
    end

    ##
    # Connects a matcher (String or an Object implementing ===) to endpoints.
    #
    def add(matcher, endpoints)
      # Maybe we have an non-String matcher. Handle the Regexp case.
      # We only keep track of matchers if it isn't a string because
      # string matchers are just pulled out of endpoints by key lookup.
      matcher = @regexp_matcher_factory.build matcher if matcher.kind_of? Regexp
      @matchers << matcher unless matcher.is_a? String

      # We add the (matcher+endpoint) into our endpoints
      @endpoints[matcher] ||= []
      @endpoints[matcher].concat endpoints
    end

    ##
    # @param [Hash] env The input message environment to match for endpoints.
    # @return [Array] List of endpoints that matched.
    #
    def match(env={})
      kind = env[:kind]
      endpoints = []
      endpoints.concat @endpoints.fetch(kind) { [] }
      @matchers.each do |matcher|
        endpoints.concat @endpoints[matcher] if matcher === env
      end
      return endpoints
    end

    ##
    # @return [Integer] Number of matchers this EndpointsMap tracks.
    #
    def size
      return @endpoints.size
    end

    ##
    # Default factory method.
    #
    def self.build(options={})
      self.new options
    end
  end

end
end
