class DevelopmentMailInterceptor
  def self.delivering_email(message)
    divider = "\n-----------------------------------------------------------------\n"
    to = "#{message.to.inspect}".html_safe
    bcc = "#{message.bcc.inspect}".html_safe
    body = "#{message.body}#{divider}BEFORE INTERCEPTOR#{divider}"
    body += "Subject = #{message.subject}\n"
    body += "To = #{to}\n"
    body += "Bcc = #{bcc}\n"
    message.subject = "#{to} #{message.subject}"
    message.to = CONFIG[:webmaster_email]
    message.bcc = nil
    message.body = body
  end
end
