require 'hashie'
require 'optser'

require 'serf/builder'
require 'serf/loader/registry'

module Serf
module Loader

  ##
  # The main loader that takes a serfup configuration file and instance evals
  # all the registered components and serfs, which populates the
  # serfup loader registry; then returns a mapping of serf kind names to
  # the instantiated serfs.
  #
  class Loader

    def initialize(*args)
      opts = Optser.extract_options! args
      @registry_class = opts.get :registry_class, Serf::Loader::Registry
      @builder_class = opts.get :builder_class, Serf::Builder
    end

    ##
    # Loads up the components defined in a serfup configuration, wires up all
    # the "exposed" serfs and returns them in a frozen map.
    #
    # Example Config:
    #
    #   # Config is a simple hash
    #   config = Hashie::Mash.new
    #   # List out the globbed filenames to load up.
    #   config.globs = [
    #     'example/**/*.serf'
    #   ]
    #   # List out the parcel kinds that we need to have serfs built up
    #   # and exposed in the returned Serf Map.
    #   config.serfs = [
    #     'subsystem/requests/create_widget'
    #   ]
    #
    # Example Env Hash:
    #
    #   env = Hashie::Mash.new
    #   env.web_service = 'http://example.com/'
    #
    # @param [Hash] opts env and basepath options
    # @option opts [Array] :globs list of file globs to load serf configs
    # @option opts [Array] :serfs list of serfs to export in Serf Map.
    # @option opts [String] :base_path root of where to run the config
    # @option opts [Hash] :env environmental variables for runtime config
    # @returns a frozen Serf Map of request parcel kind to serf.
    #
    def serfup(*args)
      opts = Optser.extract_options! args
      globs = opts.get! :globs
      serfs = opts.get! :serfs
      base_path = opts.get :base_path, '.'
      env = opts.get(:env) { Hashie::Mash.new }
      @registry = @registry_class.new env: env

      # Load in all the components listed
      globs.each do |glob_pattern|
        globs = Dir.glob File.join(base_path, glob_pattern)
        globs.each do |filename|
          File.open filename do |file|
            contents = file.read
            instance_eval(contents)
          end
        end
      end

      # Construct all the "serfs"
      map = Hashie::Mash.new
      serfs.each do |serf|
        map[serf] = @registry[serf]
        raise "Missing Serf: #{serf}" if map[serf].nil?
      end

      # return a frozen registry, clear the registry
      @registry = nil
      map.freeze
      return map
    end

    private

    ##
    # Registry attr_reader for serf files to access in the instance eval.
    def registry
      @registry
    end

    ##
    # Registry attr_reader for serf files to define a builder's work.
    def serf(*args, &block)
      @builder_class.new(*args, &block).to_app
    end

  end

end
end
