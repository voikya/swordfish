# A generic text node

module Paper
  module Node
    class Text < Base

      # Override Base append because a text node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        html = @content
        html = "<i>#{html}</i>" if @style.italic?
        html = "<b>#{html}</b>" if @style.bold?
        html = "<u>#{html}</u>" if @style.underline?
        html = "<strike>#{html}</strike>" if @style.strikethrough?
        html = "<sup>#{html}</sup>" if @style.superscript?
        html = "<sub>#{html}</sub>" if @style.subscript?
        html
      end

    end
  end
end
