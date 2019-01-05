require 'rails_helper'

RSpec.describe User, type: :model do
  let(:new_user) { create(:user) }
  let(:new_translation) { build(:user_translation) }

  context '#translation=' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when translation is correct' do
        expect do
          new_user.translation = new_translation
          new_user.save!
        end.not_to raise_error
        expect(new_user).to be_valid
      end
      it 'when translated fields values are same as expected' do
        new_user.translation = new_translation
        new_user.save!

        Globalize.with_locale(new_translation[:locale]) do
          expect(new_user.first_name).to eq(new_translation[:first_name])
          expect(new_user.middle_name).to eq(new_translation[:middle_name])
          expect(new_user.last_name).to eq(new_translation[:last_name])
        end
      end
    end

    context 'with error' do
      it 'when new translation has unknown field' do
        expect do
          new_user.translation = new_translation + { some_field: Faker::Lorem.word }
          new_user.save!
        end.to raise_error.with_message(/undefined method/)
      end
    end
  end

  context '#translations=' do # rubocop:disable RSpec/ContextWording
    it 'when new translation updates existing with same locale' do
      prev_translation = new_translation
      next_translation = build(:user_translation, locale: prev_translation[:locale])
      new_user.translations = [prev_translation, next_translation]
      new_user.save!

      Globalize.with_locale(next_translation[:locale]) do
        expect(new_user.first_name).to eq(next_translation[:first_name])
        expect(new_user.middle_name).to eq(next_translation[:middle_name])
        expect(new_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when new translation does not update existing with another locale' do
      prev_translation = new_translation
      next_translation = build(:user_translation, locale: Faker::Lorem.characters(2))
      new_user.translations = [prev_translation, next_translation]
      new_user.save!

      Globalize.with_locale(prev_translation[:locale]) do
        expect(new_user.first_name).to eq(prev_translation[:first_name])
        expect(new_user.middle_name).to eq(prev_translation[:middle_name])
        expect(new_user.last_name).to eq(prev_translation[:last_name])
      end

      Globalize.with_locale(next_translation[:locale]) do
        expect(new_user.first_name).to eq(next_translation[:first_name])
        expect(new_user.middle_name).to eq(next_translation[:middle_name])
        expect(new_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when fallback to default locale' do
      prev_translation = build(:user_translation, locale: I18n.default_locale.to_s)
      next_translation = build(:user_translation, locale: Faker::Lorem.characters(2), first_name: '', middle_name: '')
      new_user.translations = [prev_translation, next_translation]
      new_user.save!
      Globalize.with_locale(next_translation[:locale]) do
        expect(new_user.first_name).to eq(prev_translation[:first_name])
        expect(new_user.middle_name).to eq(prev_translation[:middle_name])
        expect(new_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when new translation tries to fallback to non-existing default locale' do
      other_user = nil
      Globalize.with_locale(:test) do
        other_user = create(:user)
      end
      next_translation = build(:user_translation, locale: Faker::Lorem.characters(2), first_name: '', middle_name: '')
      other_user.translations = [next_translation]
      Globalize.with_locale(next_translation[:locale]) do
        expect(other_user.first_name).to be_nil
        expect(other_user.middle_name).to be_nil
        expect(other_user.last_name).to eq(next_translation[:last_name])
      end
    end
  end

  context '#remove_translation' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when locale exists' do
        expect do
          new_user.translation = new_translation
          new_user.save!
          new_user.remove_translation(new_translation[:locale])
        end.not_to raise_error
        expect(new_user.translations.where(locale: new_translation[:locale])).to be_empty
      end
    end

    context 'with error' do
      it 'when locale does not exist' do
        expect do
          new_user.remove_translation(Faker::Lorem.characters(2))
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
