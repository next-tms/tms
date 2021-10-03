class TestMailer < ApplicationMailer
  default from: 'robot@tms.next-tms.com'

  def hello
    mail(
      subject: 'Hello from Next TMS',
      to: 'brody@next-tms.com',
      from: 'brody@tms.next-tms.com',
      html_body: '<strong>Hello</strong> there',
      track_opens: 'false',
      message_stream: 'outbound')
  end
end
