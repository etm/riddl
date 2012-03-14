module Riddl
  class InputError < ::RuntimeError; end
  class OutputError < ::RuntimeError; end
  class PathError < ::RuntimeError; end
  class BlockError < ::StandardError; end
  class SpecificationError < ::StandardError; end
end
