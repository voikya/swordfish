# A section node

module Swordfish
  module Node
    class Section < Base

      def to_html
        "<section>#{@children.map(&:to_html).join}</section>"
      end

    end
  end
end
