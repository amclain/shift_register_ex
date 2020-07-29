defmodule ShiftRegister do
  use GenServer
  use Bitwise

  require Logger

  @storage_clock_pin 31 # P9-13
  @shift_clock_pin   30 # P9-11
  @data_pin          48 # P9-15

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def play do
    send(__MODULE__, :play)
  end

  def pause do
    send(__MODULE__, :pause)
  end

  def step do
    send(__MODULE__, :step)
  end

  @impl GenServer
  def init(_) do
    {:ok, storage_clock_ref} = Circuits.GPIO.open(@storage_clock_pin, :output)
    {:ok, shift_clock_ref} = Circuits.GPIO.open(@shift_clock_pin, :output)
    {:ok, data_ref} = Circuits.GPIO.open(@data_pin, :output)

    Circuits.GPIO.write(storage_clock_ref, 0)
    Circuits.GPIO.write(shift_clock_ref, 0)
    Circuits.GPIO.write(data_ref, 0)

    state = %{
      storage_clock_ref: storage_clock_ref,
      shift_clock_ref: shift_clock_ref,
      data_ref: data_ref,
      timer_ref: nil,
      last_value: 0,
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:play, state) do
    if state.timer_ref,
      do: :timer.cancel(state.timer_ref)

    {:ok, timer_ref} = :timer.send_interval(1000, :step)

    state = %{state | timer_ref: timer_ref}

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:pause, state) do
    if state.timer_ref,
      do: :timer.cancel(state.timer_ref)

    state = %{state | timer_ref: nil}

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:step, state) do
    new_value = random_value(state.last_value)

    transfer_value(
      new_value,
      state.shift_clock_ref,
      state.data_ref,
      state.storage_clock_ref
    )

    Logger.info "Value: #{new_value}"

    state = %{state | last_value: new_value}

    {:noreply, state}
  end

  defp random_value(last_value) do
    new_value = :rand.uniform(16)

    case last_value == new_value do
      true -> random_value(last_value)
      _ -> new_value
    end
  end

  defp transfer_value(value, shift_clock_ref, data_ref, storage_clock_ref) do
    Enum.reduce(0..3, value, fn _bit_number, acc ->
      bit = acc &&& 0x1

      Circuits.GPIO.write(data_ref, bit)

      pulse_pin(shift_clock_ref)

      acc >>> 1
    end)

    pulse_pin(storage_clock_ref)
  end

  defp pulse_pin(pin_ref) do
    Circuits.GPIO.write(pin_ref, 1)
    Circuits.GPIO.write(pin_ref, 0)
  end
end
