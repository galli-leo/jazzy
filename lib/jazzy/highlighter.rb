require 'rouge'

module Jazzy
  # This module helps highlight code
  module Highlighter
    Rouge::Token::Tokens.token(:StartUSRLink, "usrs")
    Rouge::Token::Tokens.token(:EndUSRLink, "usre")

    class Formatter < Rouge::Formatters::HTML
      def initialize(language)
        @language = language
        super()
      end

      def stream(tokens, &b)
        yield "<pre class=\"highlight #{@language}\"><code>"
        tokens.each { |tok, val|
          if tok == :StartUSRLink
            yield "<a href=\"#{val}\">"
          elsif tok == :EndUSRLink
            yield "</a>"
          else
            yield span(tok, val)
          end

        }
        yield "</code></pre>\n"
      end
    end

    class SourceKitLexer < Rouge::Lexers::Swift
      prepend :root do
        rule /<[Tt]ype\susr\s?=\s?"(.*?)"\s?>(.*?)<\s?\/[Tt]ype\s?>/ do |m|
          token :StartUSRLink, m[1]
          token Keyword::Type, m[2]
          token :EndUSRLink, m[1]
        end
      end
    end

    # What Rouge calls the language
    def self.default_language
      if Config.instance.objc_mode
        'objective_c'
      else
        SourceKitLexer.new()
      end
    end

    def self.highlight(source, language = default_language)
      source && Rouge.highlight(source, language, Formatter.new(language))
    end
  end
end
