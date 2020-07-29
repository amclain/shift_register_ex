defmodule ShiftRegister.Util do
  def random_value(last_value) do
    new_value = :rand.uniform(16)

    case last_value == new_value do
      true -> random_value(last_value)
      _ -> new_value
    end
  end
end
