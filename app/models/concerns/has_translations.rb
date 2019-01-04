module HasTranslations
  def self.included(base)
    base.class_eval do
      after_commit :save_translations

      def initialize(params = {})
        unless params.nil?
          super(params.except(:translations))
          update_attributes(params)
        else
          super
        end
      end

      def update_attributes(params)
        params.except(:translations).each do |key, value|
          send("#{key}=", value)
        end

        return if params[:translations].nil?

        params[:translations].each do |item|
          translation = translations.find_or_initialize_by_locale(item[:locale])
          item.each do |key, value|
            translation.send("#{key}=".to_sym, value)
          end
        end
      end

      def save_translations
        translations.each do |item|
          item.user_id = id if item.new_record?

          item.save!
        end
      end
    end
  end
end
