module HasVersions
  extend ActiveSupport::Concern

  included do
    has_paper_trail(
      skip: skipped_versioning_attrs,
      class_name: versioning_class
    )
  end

  module ClassMethods
    def versioning_class(base_class = self)
      base_class.version_class.class_name if base_class.respond_to?(:version_class)
      'EntityVersion'
    end

    def translation_versioning_class(base_class)
      versioning_class(base_class.translation_class) if base_class.respond_to?(:translation_class)
      versioning_class(base_class)
    end

    def skipped_versioning_attrs(base_class = self)
      [] unless base_class.respond_to?(:skipped_version_attrs)
      base_class.skipped_version_attrs
    end

    def translation_versioning_options
      {
        versioning: {
          gem: :paper_trail,
          options: {
            class_name: translation_versioning_class(self)
          }
        }
      }
    end
  end
end
