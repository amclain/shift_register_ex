defmodule ShiftRegister.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    check_overlay_config()

    opts = [strategy: :one_for_one, name: ShiftRegister.Supervisor]
    children =
      [
        # {ShiftRegister.GPIO, nil},
        {ShiftRegister.SPI, nil},
      ]

    Supervisor.start_link(children, opts)
  end

  def target() do
    Application.get_env(:shift_register, :target)
  end

  defp check_overlay_config do  
    unless Nerves.Runtime.KV.get("uboot_overlay_addr4"),  
      do: configure_overlays()  
  end 

  @spec configure_overlays :: no_return 
  defp configure_overlays do  
    System.cmd("fw_setenv", ["uboot_overlay_addr4", "/lib/firmware/BB-SPIDEV0-00A0.dtbo"])  

    Logger.warn "Rebooting to apply device tree overlays" 
    Nerves.Runtime.reboot 
  end
end
