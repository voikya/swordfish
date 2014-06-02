# A hyperlink node.

module Swordfish
  module Node
    class Hyperlink < Base

      attr_accessor :href

      def to_html
        @href ||= ""
        "<a href=\"#{URI::escape(@href)}\">#{@children.map(&:to_html).join}</a>"
      end

    end
  end
end
