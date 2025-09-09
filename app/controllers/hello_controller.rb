class HelloController < ApplicationController
  before_action :set_locale
  def set_locale
    I18n.locale = params[:lang].presence || I18n.default_locale
  end

  def index
    render json: { message: "Hello, World!" }
  end

  def greet
    name = params[:name]
    if name.blank?
      error_message = I18n.t("greetings.name_required")
      render json: { error: error_message }, status: :bad_request
      return
    end
    # Look up the translation using the 't' method and pass the 'name'
    # as an interpolation variable.
    greeting_message = I18n.t("greetings.hello", name: name)
    render json: { greeting: greeting_message }
  end
end
