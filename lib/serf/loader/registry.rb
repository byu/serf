require 'hashie'
require 'optser'

require 'serf/errors/load_failure'

module Serf
module Loader

  ##
  # A Registry of components that can then be wired up
  # dependency injection style using the Service Locator Pattern.
  # Components are lazily evaluated and memoized. Thus all components
  # are singletons.
  #
  #     # Create a new registry
  #     registry = Registry.new
  #
  #     # Registers a component
  #     registry.add 'a_comp' do |r|
  #       12345
  #     end
  #
  #     # Registers b component that uses a component
  #     registry.add 'b_comp' do |r|
  #       {
  #         a_value: r['a_comp']
  #       }
  #     end
  #
  #     # Registers a Serf app (serf is helper to make and execute
  #     # a Serf::Builder), using the long form builder DSL.
  #     registry.add 'subsystem/request/my_request' do |r|
  #       # Register a serf to handle this request
  #       serf do
  #         use_defaults
  #         run MyInteractor.new(b_comp: r['b_comp'])
  #       end
  #     end
  #
  #     # Now obtain the build serf, all wired up, by the parcel kind
  #     # and execute the found serf.
  #     parcel = {
  #       kind: 'subsystem/request/my_request',
  #       message: {}
  #     }
  #     serf = registry[parcel[:kind]]
  #     puts serf.call(parcel)
  #
  class Registry
    attr_reader :blocks
    attr_reader :values
    attr_reader :env

    def initialize(*args)
      opts = Optser.extract_options! args
      @blocks = {}
      @values = {}
      @env = opts.get(:env) { Hashie::Mash.new }
    end

    ##
    # Adds a component to the registry.
    #
    # @params name the registration name of the component.
    # @params &block the proc that generates the component instance.
    #
    def add(name, &block)
      blocks[name.to_sym] = block
    end

    ##
    # Looks up a component instance by name.
    #
    # @params name the name of the component.
    # @returns the singleton instance of the component.
    #
    def [](name)
      name = name.to_sym
      return values[name] if values.has_key? name
      # No memoized value, so grab the block, call it and memoize it
      # return the block's return value, or nil.
      if block = blocks[name]
        begin
          value = block.call self, env
          values[name] = value
          blocks.delete name
          return value
        rescue => e
          raise Serf::Errors::LoadFailure.new("Name: #{name}", e)
        end
      end
    end

  end

end
end
