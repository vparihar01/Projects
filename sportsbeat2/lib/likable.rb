
module Likable
  def like_by user
    if self.id && self.persisted? && user && user.persisted?
      key = "#{self.class.table_name}:#{self.id}:likes"
      value = user.id
      return $redis.sadd key, value
    end
  end

  def liked_by? user
    if self.id && self.persisted? && user && user.persisted?
      key = "#{self.class.table_name}:#{self.id}:likes"
      value = user.id
      return $redis.sismember key, value
    end
  end

  def likes_count
    if self.id && self.persisted?
      key = "#{self.class.table_name}:#{self.id}:likes"
      return $redis.scard key
    end
  end

  def unlike_by user
    if self.id && self.persisted? && user && user.persisted?
      key = "#{self.class.table_name}:#{self.id}:likes"
      value = user.id

      return $redis.srem key, value
    end
  end
end