module Serf

  module Version
    MAJOR = 0
    MINOR = 1
    PATCH = 0
    BUILD = 'dev'
    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join '.'
  end

end
