module HasVersions
  def self.included(base)
    base.class_eval do
      def self.translation_versioning_options
        {
          fallbacks_for_empty_translations: true,
          versioning: {
            gem: :paper_trail,
            options: {
              class_name: if self.respond_to?(:translation_class)
              then
                unless self.translation_class.respond_to?(:version_class)
                then
                  'EntityVersion'
                else
                  self.translation_class.version_class.class_name
                end
              else
                'EntityVersion'
              end
            }
          }
        }
      end

      has_paper_trail(
        skip:
          unless base.respond_to?(:skipped_version_attrs)
          then
            []
          else
            base.skipped_version_attrs
          end,
        class_name:
          unless base.respond_to?(:version_class)
          then
            'EntityVersion'
          else
            base.version_class.class_name
          end
      )
    end
  end
end