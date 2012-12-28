class Hash
  # Props to the rubyfu plugin
  def slice(*slice_keys)
    slice_keys.inject({}) do |h, k|
      h[k] = self[k] if key?(k)
      h
    end
  end
end