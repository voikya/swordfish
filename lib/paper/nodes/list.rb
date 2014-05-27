# A list node

module Paper
  module Node
    class List < Base

      def to_html
        if @style.bullet?
          "<ul>#{@children.map(&:to_html).join}</ul>"
        else
          "<ol>#{@children.map(&:to_html).join}</ol>"
        end
      end

      # Get the zero-indexed depth of the bottommost child list
      # (This is not the deepest node, just the last child)
      def depth_of_final_node
        depth = 0
        node = self
        while !@children.empty? && node = node.last_list_item.nested_list do
          depth += 1
        end
        depth
      end

      # Return the final child list item (no nesting)
      def last_list_item
        @children.last
      end

    end
  end
end
