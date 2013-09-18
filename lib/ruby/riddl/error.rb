module Riddl
  class URIError < ::RuntimeError; end
  class InputError < ::RuntimeError; end
  class OutputError < ::RuntimeError; end
  class PathError < ::RuntimeError; end
  class BlockError < ::StandardError; end
  class SpecificationError < ::StandardError; end
  class ConnectionError < ::StandardError; end
end
