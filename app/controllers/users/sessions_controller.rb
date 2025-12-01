# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      if params[:s95_login].present?
        handle_s95_login
      else
        super
      end
    end

    private

    def handle_s95_login
      s95_id = params.dig(:s95_login, :s95_id).to_s.strip
      password = params.dig(:s95_login, :password)

      athlete = find_athlete_by_code(s95_id)
      user = athlete&.user

      if user&.valid_password?(password)
        sign_in(user)
        redirect_to after_sign_in_path_for(user), notice: t('devise.sessions.signed_in')
      else
        redirect_to new_user_session_path, alert: t('.invalid_s95_credentials')
      end
    end

    def find_athlete_by_code(code_string)
      return nil if code_string.blank?

      code = code_string.delete(' ').to_i
      return nil if code.zero?

      personal_code = Athlete::PersonalCode.new(code)
      Athlete.find_by(**personal_code.to_params)
    end
  end
end
