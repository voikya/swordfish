# A hyperlink node.

module Swordfish
  module Node
    class Hyperlink < Base

      attr_accessor :href

      def to_html
        "<a href='#{@href}'>#{@children.map(&:to_html).join}</a>"
      end

    end
  end
end
