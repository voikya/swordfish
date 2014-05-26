module Paper
  class Stylesheet
    
    SUPPORTED_STYLES = [
      # Inline styles
      :bold, :italic, :underline, :superscript, :subscript, :strikethrough,
      # List enumeration styles
      :bullet, :decimal, :lowerLetter, :lowerRoman
    ]

    def initialize(styles)
      @styles = []
      merge styles
    end

    def merge(styles)
      styles = [styles] unless styles.is_a?(Array)
      @styles |= styles.select{|s| SUPPORTED_STYLES.include?(s)}
    end

    private

    def has_style?(style)
      @styles.include? style
    end

    def method_missing(m, *args, &block)
      if m[-1] == '?'
        return has_style?(m[0..-2].to_sym)
      end
    end

  end
end
