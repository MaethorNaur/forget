defmodule Forget.Table do
  defmacro __using__(_opts) do
    quote do
      import Forget.Table, only: [deftable: 2]
      require Record
    end
  end

  defmacro deftable(name, [_ | _] = do_block) when is_atom(name) and not is_nil(name) do

  end

  defmacro deftable(_name, _do_block) do
    description = """
    deftable/2 require an atom as name and a non empty do block. e.g.
    deftable Test do
      fields :name
    end
    """

    raise %SyntaxError{
      file: __ENV__.file,
      line: __ENV__.line,
      description: description
    }
  end
end
