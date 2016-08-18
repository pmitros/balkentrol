-- level1map.vhd
--
-- This ROM contains the playing map. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity level1map is port(
             clk       : in std_logic;
             x, y      : in std_logic_vector(7 downto 0);
             level     : out std_logic);
end level1map;
architecture rominterface of level1map is
  signal romaddr : std_logic_vector(9 downto 0);
  signal levelint  : std_logic_vector(0 downto 0);
begin
  
  romaddr <= y(6 downto 0)&x(3 downto 1);
  process(levelint, x)
  begin
    if x(7 downto 4)="0000" then
      level <= levelint(0);
    else
      level <= '0';
    end if;
  end process;
  
  rom_inst: lpm_rom
      GENERIC MAP (lpm_widthad => 10,
                   lpm_width => 1,
                   lpm_file => "level1.mif",
                   lpm_address_control => "UNREGISTERED",
                   lpm_outdata => "UNREGISTERED")
      PORT MAP (q => levelint, address => romaddr);--, outclock=>clk);
end rominterface;

