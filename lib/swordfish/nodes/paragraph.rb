# A paragraph node

module Swordfish
  module Node
    class Paragraph < Base

      def to_html
        if @content
          "<p>#{@content}</p>"
        else
          "<p>#{@children.map(&:to_html).join}</p>"
        end
      end

    end
  end
end
