require 'jazzy/source_declaration'
require 'jazzy/config'
require 'jazzy/source_mark'
require 'jazzy/jazzy_markdown'

module Jazzy
  # Category (group, contents) pages generated by jazzy
  class SourceCategory < SourceDeclaration
    extend Config::Mixin

    def initialize(group, name, abstract, url_name)
      super()
      self.type     = SourceDeclaration::Type.overview
      self.name     = name
      self.url_name = url_name
      self.abstract = Markdown.render(abstract)
      self.children = group
      self.parameters = []
    end

    # Group root-level docs into custom categories or by type
    def self.group_docs(docs)
      custom_categories, docs =
        group_custom_categories(docs, config.custom_categories)
      type_categories, uncategorized = group_type_categories(
        docs, custom_categories.any? ? 'Other ' : ''
      )
      custom_categories + type_categories + uncategorized
    end

    def self.group_custom_categories(docs, categories)
      group = categories.map do |category|
        children = category['children'].flat_map do |child|
          if child.is_a?(Hash)
            # Nested category, recurse
            children, docs = group_custom_categories(docs, [child])
          else
            # Doc name, find it
            children, docs = docs.partition { |doc| doc.name == child }
            if children.empty?
              STDERR.puts(
                'WARNING: No documented top-level declarations match ' \
                "name \"#{child}\" specified in categories file",
              )
            end
          end
          children
        end
        # Category config overrides alphabetization
        children.each.with_index { |child, i| child.nav_order = i }
        make_group(children, category['name'], '')
      end
      [group.compact, docs]
    end

    def self.group_type_categories(docs, type_category_prefix)
      group = SourceDeclaration::Type.all.map do |type|
        children, docs = docs.partition { |doc| doc.type == type }
        make_group(
          children,
          type_category_prefix + type.plural_name,
          "The following #{type.plural_name.downcase} are available globally.",
          type_category_prefix + type.plural_url_name,
        )
      end
      [group.compact, docs]
    end

    def self.make_group(group, name, abstract, url_name = nil)
      group.reject! { |doc| doc.name.empty? }
      unless group.empty?
        SourceCategory.new(group, name, abstract, url_name)
      end
    end

    def level
      return self.documentation_path.length
    end
  end
end
