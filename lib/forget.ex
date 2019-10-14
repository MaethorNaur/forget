defmodule Forget do
  @moduledoc """
  Documentation for Forget.
  """

  @typedoc """
  Configuration
  """
  @type arg :: {:config, config}

  @typedoc """
  Configuration
  """
  @type init_args :: [arg]

  @typedoc """
  Configuration
  """
  @type config :: [{:schema, term()}, {:cluster, cluster}]

  @type cluster :: [{:quorum, pos_integer()}]
end
