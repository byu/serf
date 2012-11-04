require 'serf/util/options_extraction'

class OptionsExtractionWrapper
  include Serf::Util::OptionsExtraction

  def initialize(*args)
    extract_options! args
  end

end
