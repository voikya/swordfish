module Paper
  module Node
    class Table < Base

      def rows
        @children.length
      end

      def cols
        @children[0].children.length
      end

      def cell_at(row, col)
        @children[row].children[col]
      end

      def to_html
        collapse_cells!
        "<table>#{@children.map(&:to_html).join}</table>"
      end

      private

      def collapse_cells!
        structure = []
        rows.times do
          r = []
          cols.times do
            r << {:colspan => 1, :rowspan => 1}
          end
          structure << r
        end
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

        rows.times do |r|
          cols.times do |c|
            cell_at(r, c).inform!(structure[r][c] || {:colspan => 0, :rowspan => 0})
          end
        end
      end

    end
  end
end
