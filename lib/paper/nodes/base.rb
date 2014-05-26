module Paper
  module Node
    class Base

      attr_accessor :content
      attr_reader :children
      attr_reader :style

      def initialize
        @style = Paper::Stylesheet.new []
        @children = []
      end

      def append(node)
        @children ||= []
        @children << node
        @children.flatten!
      end

      def stylize(styles)
        @style.merge styles
      end

      def to_html
        raise NotImplementedError
      end

      def inform!(hash)
        hash.each do |k, v|
          instance_variable_set "@#{k}", v
        end
      end

    end

    class BadContentError < Exception
    end
  end
end
