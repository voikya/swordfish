# A table cell node

module Paper
  module Node
    class TableCell < Base

      attr_accessor :merge_left
      attr_accessor :merge_up
      attr_reader :rowspan
      attr_reader :colspan

      # True if this cell is merged with the one to the left
      def merge_left?
        !!@merge_left
      end

      # True if this cell is merged with the one above
      def merge_up?
        !!@merge_up
      end

      def to_html
        return nil if @colspan == 0 && @rowspan == 0

        if @rowspan && @rowspan > 1
          rowspan = " rowspan=#{@rowspan}"
        end
        if @colspan && @colspan > 1
          colspan = " colspan=#{@colspan}"
        end

        "<td#{rowspan}#{colspan}>#{@children.map(&:to_html).join}</td>"
      end

    end
  end
end
