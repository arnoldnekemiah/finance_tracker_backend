class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM', 'noreply@ikondesoft.com')
  layout "mailer"
end
