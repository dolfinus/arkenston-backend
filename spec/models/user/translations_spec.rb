require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:existing_user) { create(:user) }
  let(:new_translation) { build(:user_translation) }

  context '#translation=' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when translation is correct' do
        expect do
          existing_user.translation = new_translation
          existing_user.save!
        end.not_to raise_error
        expect(existing_user).to be_valid
      end
      it 'when translated fields values are same as expected' do
        existing_user.translation = new_translation
        existing_user.save!

        Globalize.with_locale(new_translation[:locale]) do
          expect(existing_user.first_name).to eq(new_translation[:first_name])
          expect(existing_user.middle_name).to eq(new_translation[:middle_name])
          expect(existing_user.last_name).to eq(new_translation[:last_name])
        end
      end
    end

    context 'with error' do
      it 'when new translation locale is unknown' do
        expect do
          existing_user.translation = build(:user_translation, :unknown_locale)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
      it 'when new translation has unknown field' do
        expect do
          existing_user.translation = build(:user_translation, some_field: Faker::Lorem.word)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  context '#translations=' do # rubocop:disable RSpec/ContextWording
    it 'when new translation updates existing with same locale' do
      prev_translation = new_translation
      next_translation = build(:user_translation, locale: prev_translation[:locale])
      existing_user.translations = [prev_translation, next_translation]
      existing_user.save!

      Globalize.with_locale(next_translation[:locale]) do
        expect(existing_user.first_name).to eq(next_translation[:first_name])
        expect(existing_user.middle_name).to eq(next_translation[:middle_name])
        expect(existing_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when new translation does not update existing with another locale' do
      prev_translation = new_translation
      next_translation = build(:user_translation, :known_locale)
      puts new_translation[:locale]
      puts next_translation[:locale]
      existing_user.translations = [prev_translation, next_translation]
      existing_user.save!

      Globalize.with_locale(prev_translation[:locale]) do
        expect(existing_user.first_name).to eq(prev_translation[:first_name])
        expect(existing_user.middle_name).to eq(prev_translation[:middle_name])
        expect(existing_user.last_name).to eq(prev_translation[:last_name])
      end

      Globalize.with_locale(next_translation[:locale]) do
        expect(existing_user.first_name).to eq(next_translation[:first_name])
        expect(existing_user.middle_name).to eq(next_translation[:middle_name])
        expect(existing_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when fallback to default locale' do
      prev_translation = build(:user_translation)
      next_translation = build(:user_translation, :known_locale, first_name: '', middle_name: '')
      existing_user.translations = [prev_translation, next_translation]
      existing_user.save!
      Globalize.with_locale(next_translation[:locale]) do
        expect(existing_user.first_name).to eq(prev_translation[:first_name])
        expect(existing_user.middle_name).to eq(prev_translation[:middle_name])
        expect(existing_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when new translation tries to fallback to non-existing default locale' do
      other_user = nil
      Globalize.with_locale(:test) do
        other_user = create(:user)
      end
      next_translation = build(:user_translation, :known_locale, first_name: '', middle_name: '')
      other_user.translations = [next_translation]
      Globalize.with_locale(next_translation[:locale]) do
        expect(other_user.first_name).to be_nil
        expect(other_user.middle_name).to be_nil
        expect(other_user.last_name).to eq(next_translation[:last_name])
      end
    end
  end

  context '.new' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when no :translations are in attributes' do
        new_user = User.new(name: user.name,
                            email: user.email,
                            role: user.role,
                            password: Faker::Internet.password)
        expect(new_user.first_name).to be_blank
        expect(new_user.middle_name).to be_blank
        expect(new_user.last_name).to be_blank
      end
      it 'when :translations are in attributes' do
        new_user = User.new(name: user.name,
                            email: user.email,
                            role: user.role,
                            password: Faker::Internet.password,
                            translations: [new_translation])
        expect { new_user.save! }.not_to raise_error
        Globalize.with_locale(new_translation[:locale]) do
          expect(new_user.first_name).to eq(new_translation[:first_name])
          expect(new_user.middle_name).to eq(new_translation[:middle_name])
          expect(new_user.last_name).to eq(new_translation[:last_name])
        end
      end
    end
  end

  context '#update_attributes' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when no :translations are in new attributes' do
        old_first_name  = existing_user.first_name
        old_middle_name = existing_user.middle_name
        old_last_name   = existing_user.last_name
        expect do
          attributes = { name: Faker::Lorem.word }
          existing_user.update_attributes(attributes)
          existing_user.save!
        end.not_to raise_error
        expect(existing_user.first_name).to eq(old_first_name)
        expect(existing_user.middle_name).to eq(old_middle_name)
        expect(existing_user.last_name).to eq(old_last_name)
      end
      it 'when :translations are in new attributes' do
        expect do
          attributes = { name: Faker::Lorem.word, translations: [new_translation] }
          existing_user.update_attributes(attributes)
          existing_user.save!
        end.not_to raise_error
        Globalize.with_locale(new_translation[:locale]) do
          expect(existing_user.first_name).to eq(new_translation[:first_name])
          expect(existing_user.middle_name).to eq(new_translation[:middle_name])
          expect(existing_user.last_name).to eq(new_translation[:last_name])
        end
      end
    end
  end

  context '#remove_translation' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when locale exists' do
        expect do
          existing_user.translation = new_translation
          existing_user.save!
          existing_user.remove_translation(new_translation[:locale])
        end.not_to raise_error
        expect(existing_user.translations.where(locale: new_translation[:locale])).to be_empty
      end
    end

    context 'with error' do
      it 'when locale does not exist' do
        expect do
          existing_user.remove_translation(build(:user_translation, :unknown_locale)[:locale])
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
