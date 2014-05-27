# A table node

module Paper
  module Node
    class Table < Base

      # Get the number of rows in the table
      def rows
        @children.length
      end

      # Get the number of columns in the table
      def cols
        @children[0].children.length
      end

      # Return the TableCell object at a given position
      def cell_at(row, col)
        @children[row].children[col]
      end

      def to_html
        collapse_cells!
        "<table>#{@children.map(&:to_html).join}</table>"
      end

      private

      # A Paper::Node::Table always contains rows*cols cells, even
      # if some of them are to be merged. This method determines how
      # cells ought to be merged together and then informs each cell
      # of its configuration, so that each cell will then properly know
      # how to render itself (if at all).
      def collapse_cells!
        # Create a 2D array representing each cell, and give each one
        # an initial colspan and rowspan of 1
        structure = []
        rows.times do
          r = []
          cols.times do
            r << {:colspan => 1, :rowspan => 1}
          end
          structure << r
        end

        # Iterate over each table cell and see if it has the merge_up
        # or merge_left properties set. If so, find the corresponding
        # "parent" cell and incremenet its colspan or rowspan appropriately.
        # If the cell is to be merged up or left, set its value to nil
        # within the "structure" variable.
        rows.times do |r|
          cols.times do |c|
            if cell_at(r, c).merge_up?
              (r-1).downto(0).each do |i|
                unless structure[i][c].nil?
                  structure[i][c][:rowspan] += 1
                  break
                end
              end
              structure[r][c] = nil
            end
            if cell_at(r, c).merge_left?
              (c-1).downto(0).each do |i|
                unless structure[r][i].nil?
                  structure[r][i][:colspan] += 1
                  break
                end
              end
              structure[r][c] = nil
            end
          end
        end

        # Inform every table cell of its calculated colspan and rowspan.
        # If the cell is not to be drawn, set its rowspan and colspan to 0.
        rows.times do |r|
          cols.times do |c|
            cell_at(r, c).inform!(structure[r][c] || {:colspan => 0, :rowspan => 0})
          end
        end
      end

    end
  end
end
