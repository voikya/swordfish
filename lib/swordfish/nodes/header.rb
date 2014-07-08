# A header node

module Swordfish
  module Node
    class Header < Base

      attr_accessor :level
      attr_accessor :is_section_header

      def to_html
        raise "Missing header level" unless @level
        tag = @level <= 6 ? "h#{@level}" : "h6"
        text = @children.map(&:to_html).join
        "<#{tag}>#{text}</#{tag}>"
      end

    end
  end
end
