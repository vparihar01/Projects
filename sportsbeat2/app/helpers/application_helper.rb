module ApplicationHelper
  def title
    return @title || "SportsBeat"
  end

  def preloaded_json
    if @preloaded_json && @preloaded_json.is_a?(Hash)
      @preloaded_json.to_json
    else
      "{}"
    end
  end
end
