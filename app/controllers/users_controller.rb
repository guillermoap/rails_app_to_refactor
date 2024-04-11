# frozen_string_literal: true

class UsersController < ApplicationController
  def create
    # TODO: move this to a specific method, maybe 'create_params'
    # We might need to reuse this in other actions, maybe make it more generic so separating it into a method would DRY it up.
    # Also help with mocking in specs
    user_params = params.require(:user).permit(:name, :email, :password, :password_confirmation)

    # TODO: Move this to the User model, and handle the sanitizing of the password via a validation, but more specifically the normalize callback. Might need to add class attributes that are not present in the DB schema.
    password = user_params[:password].to_s.strip
    password_confirmation = user_params[:password_confirmation].to_s.strip

    # TODO: Abstract this into its own class/module to encapsulate registration logic and constraints.
    errors = {}
    errors[:password] = ["can't be blank"] if password.blank?
    errors[:password_confirmation] = ["can't be blank"] if password_confirmation.blank?

    # if registration_service.call
    #   success response
    # else
    #   error resposnse
    # end

    if errors.present?
      render_json(422, user: errors)
    else
      if password != password_confirmation
        render_json(422, user: { password_confirmation: ["doesn't match password"] })
      else
        password_digest = Digest::SHA256.hexdigest(password)
        # TODO: same comment as line 14. Would encapsulate this together with the other contraints and User create/registration
        user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          token: SecureRandom.uuid,
          password_digest: password_digest
        )

        if user.save
          render_json(201, user: user.as_json(only: [:id, :name, :token]))
        else
          render_json(422, user: user.errors.as_json)
        end
      end
    end
  end

  def show
    # TODO: Use a before_action except: [:create] to validate and authenticate
    perform_if_authenticated
  end

  def destroy
    perform_if_authenticated do
      current_user.destroy
    end
  end

  private

    def perform_if_authenticated(&block)
      authenticate_user do
        block.call if block

        render_json(200, user: { email: current_user.email })
      end
    end
end
