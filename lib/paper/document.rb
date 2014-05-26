require 'paper/stylesheet'
require 'paper/nodes/base'
require 'paper/nodes/text'
require 'paper/nodes/paragraph'
require 'paper/nodes/list'
require 'paper/nodes/list_item'
require 'paper/nodes/hyperlink'
require 'paper/nodes/table'
require 'paper/nodes/table_row'
require 'paper/nodes/table_cell'

module Paper
  class Document
    attr_reader :nodes

    def initialize
      @nodes = []
    end

    def append(node)
      @nodes << node
    end

    def to_html
      @nodes.map(&:to_html).join
    end
  end
end
