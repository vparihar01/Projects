module MailersHelper
  def divider
    "-----------------------------------------------------------------"
  end

  def server_info(server)
    return nil if server.blank?
    server = Uploader.new(server) if server.is_a?(String)
    if server.is_a?(Uploader)
      str = "  Host: #{server.host}\n"
      str += "  Path: #{server.path}\n" if server.path
      str += "  User: #{server.user}\n"
    else
      FEEDBACK.error("Argument passed cannot be coerced to Uploader class '#{server.inspect}'")
      return nil
    end
  end
end
