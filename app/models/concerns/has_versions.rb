module HasVersions
  def self.included(base)
    base.class_eval do
      def self.versioning_class(base_class = self)
        base_class.version_class.class_name if base_class.respond_to?(:version_class)
        'EntityVersion'
      end

      def self.translation_versioning_class(base_class)
        versioning_class(base_class.translation_class) if base_class.respond_to?(:translation_class)
        versioning_class(base_class)
      end

      def self.skipped_versioning_attrs(base_class = self)
        [] unless base_class.respond_to?(:skipped_version_attrs)
        base_class.skipped_version_attrs
      end

      def self.translation_versioning_options
        {
          fallbacks_for_empty_translations: true,
          versioning: {
            gem: :paper_trail,
            options: {
              class_name: translation_versioning_class(self)
            }
          }
        }
      end

      has_paper_trail(
        skip: base.skipped_versioning_attrs,
        class_name: base.versioning_class
      )
    end
  end
end
