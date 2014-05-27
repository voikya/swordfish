# A paragraph node

module Swordfish
  module Node
    class Paragraph < Base

      def to_html
        if @content
          "<p>#{@content}</p>"
        else
          text = @children.map(&:to_html).join
          "<p>#{text}</p>" unless text.length.zero?
        end
      end

    end
  end
end
