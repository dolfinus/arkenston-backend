require 'rails_helper'

RSpec.describe User, type: :model do
  let(:new_user) { create(:user) }
  let(:new_translation) { build(:user_translation) }

  context '.new' do # rubocop:disable RSpec/ContextWording
    context 'is valid' do
      it 'when attributes are correct' do
        expect(build(:user)).to be_valid
      end
    end

    context 'is not valid' do
      it 'without name' do
        expect(build(:user, name: nil)).not_to be_valid
      end
      it 'without email' do
        expect(build(:user, email: nil)).not_to be_valid
      end
      it 'without password' do
        expect(build(:user, password: nil)).not_to be_valid
      end
      it 'with name contains non-latin symbols' do
        expect(build(:user, name: 'Тест')).not_to be_valid
      end
      it 'with wrong formated email' do
        expect(build(:user, email: Faker::Lorem.word)).not_to be_valid
      end
      it 'with unknown role' do
        expect { build(:user, role: Faker::Lorem.word.to_sym) }.to raise_error.with_message(/is not a valid role/)
      end
      it 'without any translation' do
        expect(build(:user, first_name: nil, last_name: nil, middle_name: nil)).not_to be_valid
      end
      it 'with name already used' do
        existing_user = create(:user)
        double_user = build(:user, name: existing_user.name)
        expect(double_user).not_to be_valid
      end
      it 'with email already used' do
        existing_user = create(:user)
        double_user = build(:user, email: existing_user.email)
        expect(double_user).not_to be_valid
      end
    end
  end

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
      next_translation = build(:user_translation, locale: Faker::Lorem.characters(2), first_name: nil, middle_name: nil)
      new_user.translations = [prev_translation, next_translation]
      new_user.save!
      Globalize.with_locale(next_translation[:locale]) do
        expect(new_user.first_name).to eq(prev_translation[:first_name])
        expect(new_user.middle_name).to eq(prev_translation[:middle_name])
        expect(new_user.last_name).to eq(next_translation[:last_name])
      end
    end
    it 'when new translation tries to fallback to non-existing with default locale' do
      other_user = nil
      Globalize.with_locale(:test) do
        other_user = create(:user)
      end
      next_translation = build(:user_translation, locale: Faker::Lorem.characters(2), first_name: nil, middle_name: nil)
      other_user.translations = [next_translation]
      Globalize.with_locale(next_translation[:locale]) do
        expect(other_user.first_name).to eq(next_translation[:first_name])
        expect(other_user.middle_name).to eq(next_translation[:middle_name])
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

  context '#anonymous' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when Anonymous name is "anonymous"' do
        expect(User.anonymous_name).to eq('anonymous')
      end
      it 'when Anonymous is exist' do
        expect(User.anonymous).not_to be_nil
      end
    end

    context 'with error' do
      it 'when Anonymous has no email and password' do
        expect(User.anonymous).not_to be_valid
      end
    end
  end
end
