-- circlemap.vhd
--
-- This ROM contains a circle. Passing a coordinate returns 1 or 0.
-- We can store 1/4 of the circle; we'll do this if we need to optimize
-- for size. Right now, we're optimizing for speed. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity circlemap is port(
             clk      : in std_logic;
             x, y     : in std_logic_vector(9 downto 0);
             z        : in std_logic_vector(9 downto 0);
             pixel    : out std_logic);
end circlemap;
architecture rominterface of circlemap is
  signal romaddr : std_logic_vector(9 downto 0);
  signal pixint  : std_logic_vector(0 downto 0);
  signal xint, yint : std_logic_vector(4 downto 0);
  signal yballmin, yballmax : std_logic_vector(9 downto 0);
begin
  yballmin <= 383 - z;
  yballmax <= 416 - z;

  xint <= x(4 downto 0);
  yint <= y(4 downto 0)+z(4 downto 0);
  
  romaddr <= yint&xint;

  process (x, y, pixint)
  begin  -- process
    if x > 303 and x < 336 and y > yballmin and y < yballmax then 
      pixel <= pixint(0);
    else
      pixel <= '0';
    end if;
  end process;
  
  rom_inst: lpm_rom
      GENERIC MAP (lpm_widthad => 10,
                   lpm_width => 1,
                   lpm_file => "circle.mif",
                   lpm_address_control => "UNREGISTERED",
                   lpm_outdata => "UNREGISTERED")
      PORT MAP (q => pixint, address => romaddr);
end rominterface;

