-- shadowmap.vhd
--
-- This ROM contains the shape of the shadow. It's basically an egg.
-- It's close enough to a circle that we could use circlemap if we were
-- desperate. We're not desperate yet.  

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity shadowmap is port(
             clk      : in std_logic;
             x, y     : in std_logic_vector(9 downto 0);
             pixel    : out std_logic);
end shadowmap;
architecture rominterface of shadowmap is
  signal romaddr : std_logic_vector(9 downto 0);
  signal pixint  : std_logic_vector(0 downto 0);
  signal xint, yint : std_logic_vector(4 downto 0);
  signal yshadowmin, yshadowmax : std_logic_vector(9 downto 0);
begin
  yshadowmin <= "0110001111";
  yshadowmax <= "0110110000";

  xint <= x(4 downto 0);
  yint <= 15-y(4 downto 0);
  
  romaddr <= yint&xint;

  process (x, y, pixint)
  begin  -- process
    if rising_edge(clk) then
      if x > 304 and x < 337 and y > yshadowmin and y < yshadowmax then 
        pixel <= pixint(0);
      else
        pixel <= '0';
      end if;      
    end if;
  end process;
  
  rom_inst: lpm_rom
      GENERIC MAP (lpm_widthad => 10,
                   lpm_width => 1,
                   lpm_file => "shadowmap.mif",
                   lpm_address_control => "UNREGISTERED",
                   lpm_outdata => "UNREGISTERED")
      PORT MAP (q => pixint, address => romaddr);--, outclock => clk);
end rominterface;

