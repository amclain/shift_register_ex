defmodule ShiftRegister.SPI do
  alias ShiftRegister.Util

  use GenServer

  require Logger

  # SPI pins:
  #   P9-17 - Storage register clock
  #   P9-22 - Shift register clock
  #   P9-21 - Serial data

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
    {:ok, spi_ref} = Circuits.SPI.open("spidev1.0")

    state = %{
      spi_ref: spi_ref,
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
    new_value = Util.random_value(state.last_value)

    {:ok, _rx_data} = Circuits.SPI.transfer(state.spi_ref, <<new_value>>)

    Logger.info "Value: #{new_value}"

    state = %{state | last_value: new_value}

    {:noreply, state}
  end
end
