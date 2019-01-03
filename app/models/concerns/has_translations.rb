module HasTranslations
  def self.included(base)
    base.class_eval do
      after_commit :save_translations

      def initialize(params = {})
        super(params.except(:translations))
        update_attributes(params) unless params.nil?
      end

      def update_attributes(params)
        params.except(:translations).each do |key, value|
          self.send("#{key.to_s}=", value)
        end
    
        if not params[:translations].nil?
          params[:translations].each do |item|
            translation = self.translations.find_or_initialize_by_locale(item[:locale])
            item.each do |key, value|
              translation.send("#{key.to_s}=".to_sym, value)
            end
          end
        end
      end

      def save_translations
        translations.each do |item|
          if item.new_record?
            item.user_id = self.id
          end
          item.save!
        end
      end
    end
  end
end