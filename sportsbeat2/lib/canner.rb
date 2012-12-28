class Canner < SimpleDelegator
  def initialize o, ability
    @ability = ability
    super o
  end

  def ability
    @ability
  end

  def can? action, *extra_args
    @ability.can? action, __getobj__(), *extra_args
  end

  def cannot? action, *extra_args
    @ability.cannot? action, __getobj__(), *extra_args
  end
end