class UserMailerPreview < ActionMailer::Preview
  def send_welcome
    UserMailer.send_welcome(User.first)
  end
end
