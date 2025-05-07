# frozen_string_literal: true

# Example:
#     validates :recaptcha_token, recaptcha: { score: 0.5 }, on: :create
class RecaptchaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, token)
    return if Katalyst::GoogleApis.config.recaptcha.test_mode

    action     = options.fetch(:action, record.class.model_name.param_key)
    project_id = options.fetch(:project_id, Katalyst::GoogleApis.config.project_id)
    score      = options.fetch(:score, Katalyst::GoogleApis.config.recaptcha.score)
    site_key   = options.fetch(:site_key, Katalyst::GoogleApis.config.recaptcha.site_key)

    if token.blank?
      record.errors.add(attribute, :recaptcha_blank)
      return
    end

    response = Katalyst::GoogleApis::Recaptcha::AssessmentService.call(
      parent:     "projects/#{project_id}",
      assessment: { event: { site_key:, token: } },
    )

    if !response.valid?
      record.errors.add(attribute, :recaptcha_invalid)
    elsif response.action != action
      record.errors.add(attribute, :recaptcha_action_mismatch)
    elsif response.score < score
      record.errors.add(attribute, :recaptcha_suspicious)
    end
  end
end
