-- incrementrom.vhd
--
-- Thin layer used to pick out increment and initial positions from ROM.
-- In the future, may be used to calculate them.
--
-- We have enough time during refresh, and by changing them, we could do
-- cool camera effects :)

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity incrementrom is port(
             clk       : in std_logic;
             vline     : in std_logic_vector(8 downto 0);
             increment : out std_logic_vector(15 downto 0);
             initposx  : out std_logic_vector(23 downto 0);
             initposy  : out std_logic_vector(22 downto 0)
             );
end incrementrom;
architecture romaccess of incrementrom is
begin
  rominst: lpm_rom
      GENERIC MAP (lpm_widthad => 9,
                   lpm_width => 16,
                   lpm_file => "increment.mif",
                   lpm_address_control => "UNREGISTERED",
                   lpm_outdata => "UNREGISTERED",
                   lpm_numwords => 480)
      PORT MAP (q => increment, address => vline);
      initposx <= (others => '0');
      initposy <= (others => '0');
end romaccess;
