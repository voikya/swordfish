# A paragraph node

module Swordfish
  module Node
    class Paragraph < Base

      def to_html
        if @content
          "<p>#{@content}</p>"
        elsif @children.length == 1 && @children[0].is_a?(Swordfish::Node::Image)
          # If the only child is an image, don't bother putting it in a P tag
          @children.map(&:to_html).join
        else
          text = @children.map(&:to_html).join
          "<p>#{text}</p>" unless text.length.zero?
        end
      end

    end
  end
end
