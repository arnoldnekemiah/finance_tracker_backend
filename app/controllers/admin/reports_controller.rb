class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access

  def generate_daily
    authorize! :manage, :reports
    
    report = Admin::ReportGenerator.generate_daily_report
    
    render json: {
      message: 'Daily report generated successfully',
      report: report
    }
  end

  def generate_weekly
    authorize! :manage, :reports
    
    report = Admin::ReportGenerator.generate_weekly_report
    
    render json: {
      message: 'Weekly report generated successfully',
      report: report
    }
  end

  def generate_monthly
    authorize! :manage, :reports
    
    report = Admin::ReportGenerator.generate_monthly_report
    
    render json: {
      message: 'Monthly report generated successfully',
      report: report
    }
  end

  def generate_custom
    authorize! :manage, :reports
    
    start_date = parse_date(params[:start_date])
    end_date = parse_date(params[:end_date])
    
    if start_date.nil? || end_date.nil?
      render json: {
        error: 'Invalid date parameters. Please provide start_date and end_date in YYYY-MM-DD format'
      }, status: :bad_request
      return
    end

    if start_date > end_date
      render json: {
        error: 'Start date cannot be after end date'
      }, status: :bad_request
      return
    end

    report = Admin::ReportGenerator.new.generate_custom_report(start_date, end_date)
    
    render json: {
      message: 'Custom report generated successfully',
      report: report
    }
  end

  def schedule_reports
    authorize! :manage, :reports
    
    # This would typically integrate with a job scheduler like Sidekiq or cron
    # For now, we'll just return the scheduling configuration
    
    render json: {
      message: 'Report scheduling configured',
      schedule: {
        daily_reports: {
          enabled: true,
          time: '06:00 UTC',
          description: 'Generated daily at 6 AM UTC'
        },
        weekly_reports: {
          enabled: true,
          day: 'Monday',
          time: '07:00 UTC',
          description: 'Generated every Monday at 7 AM UTC'
        },
        monthly_reports: {
          enabled: true,
          day: 1,
          time: '08:00 UTC',
          description: 'Generated on the 1st of each month at 8 AM UTC'
        }
      }
    }
  end

  private

  def ensure_admin_access
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
end
