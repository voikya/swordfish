# A generic text node

module Swordfish
  module Node
    class Text < Inline

      # Override Base append because a text node should never have children
      def append(node)
        raise BadContentError
      end

      def to_html
        @content ||= ""
        @content.gsub!(/[[:space:]]/, ' ')
        leading_space = !!@content.lstrip!  # If there is a leading or trailing space,
        trailing_space = !!@content.rstrip! # shift it outside of any formatting tags
        html = CGI::escapeHTML(@content)
        if html.length > 0
          html = "<i>#{html}</i>" if @style.italic?
          html = "<b>#{html}</b>" if @style.bold?
          html = "<u>#{html}</u>" if @style.underline?
          html = "<strike>#{html}</strike>" if @style.strikethrough?
          html = "<sup>#{html}</sup>" if @style.superscript?
          html = "<sub>#{html}</sub>" if @style.subscript?
          html = "<strong>#{html}</strong>" if @style.strong?
          html = "<em>#{html}</em>" if @style.emphasis?
        end
        html = "#{' ' if leading_space}#{html}#{' ' if trailing_space}"
        html
      end

    end
  end
end
