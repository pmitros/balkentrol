-- circlerom.vhd
--
-- This ROM contains a circle. Passing a coordinate returns 1 or 0.
-- We can store 1/4 of the circle; we'll do this if we need to optimize
-- for size. Right now, we're optimizing for speed. 
--
-- This code is just syntactic sugar. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity circlerom is port(
             clk      : in std_logic;
             x, y     : in std_logic_vector(4 downto 0);
             --romaddr : in std_logic_vector(9 downto 0);
             pixel    : out std_logic);
end circlerom;
architecture rominterface of circlerom is
  signal romaddr : std_logic_vector(9 downto 0);
  signal pixint  : std_logic_vector(0 downto 0);
begin
  romaddr <= y&x;
  pixel <= pixint(0);
  rom_inst: lpm_rom
      GENERIC MAP (lpm_widthad => 10,
                   lpm_width => 1,
                   lpm_file => "circle.mif",
                   lpm_address_control => "UNREGISTERED",
                   lpm_outdata => "UNREGISTERED")
      PORT MAP (q => pixint, address => romaddr);
end rominterface;

