class KudosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_result

  def create
    @kudo = @result.kudos.build(athlete: current_user.athlete)
    if @kudo.save
      notify_athlete
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to root_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @kudo = @result.kudos.find_by!(athlete: current_user.athlete)
    @kudo.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to root_path }
    end
  end

  private

  def set_result
    @result = Result.find(params[:result_id])
  end

  def notify_athlete
    return unless @result.athlete&.user&.telegram_id

    Telegram::Notification::KudoJob.perform_later(
      @result.athlete.user.telegram_id,
      current_user.athlete.name,
      @result.total_time_string,
      @result.activity.event.name
    )
  end
end
