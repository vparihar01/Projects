class ContestCriteriaEvaluator
  def initialize blob
    @json = MultiJson.load blob
    @json.each do |k, v|
      if !v.is_a?(Array)
        @json[k] = [v]
      end
    end
  end

  def accept_gender? user
    ok = true

    if @json["gender"]
      ok = false
      @json["gender"].each do |r|
        ok ||= (user.gender == g)
      end
    end

    return ok
  end

  def accept_role? user
    ok = true

    if @json["role"]
      ok = false
      @json["role"].each do |r|
        ok ||= user.has_role?(r)
      end
    end

    return ok
  end

  def accept_school? user
    ok = true

    if @json["school"]
      ok = user.current_athletes.where(:school_id => @json["school"]).count > 0
    end

    return ok
  end

  def accept_sport? user
    ok = true

    if @json["sport"]
      ok = user.current_teams.where(:sport_id => @json["sport"]).count > 0
    end

    return ok
  end

  def accept_team? user
    ok = true

    if @json["team"]
      ok = user.current_teams.where(:level => @json["team"]).count > 0
    end

    return ok
  end

  def accept? user
    ok = true
    ok &&= accept_role? user
    ok &&= accept_gender? user
    ok &&= accept_school? user
    ok &&= accept_sport? user
    ok &&= accept_team? user
    return ok
  end
end