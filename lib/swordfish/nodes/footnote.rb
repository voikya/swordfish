# A foonote node

module Swordfish
  module Node
    class Footnote < Base

      attr_accessor :index

      def to_html
        return "" unless @index
        "<a id='footnote-ref-#{@index}' href='#footnote-#{@index}'>[#{@index}]</a>"
      end

      def content_to_html
        return "" unless @index
        "<p><a id='footnote-#{@index}' href='#footnote-ref-#{@index}'>[#{@index}]</a> #{@children.map(&:to_html).join}</p>"
      end

    end
  end
end
