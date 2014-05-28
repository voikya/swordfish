# A list node

module Swordfish
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

      # Return the final child list
      def last_list
        node = self
        while node.children && node.last_list_item.nested_list
          node = node.last_list_item.nested_list
        end
        node
      end

      # Return the final child list item
      def last_list_item(opts = {})
        if opts[:recurse]
          node = self
          li = @children.last
          while node.children && node = node.last_list_item.nested_list
            li = node.children.last
          end
          li
        else
          @children.last
        end
      end

    end
  end
end
