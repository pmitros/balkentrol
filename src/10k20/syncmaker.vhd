-- syncmaker.vhd
--
-- Generates the hsync and vsync signals, as well as an output that
-- lets us know if we're on-screen

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity syncmaker is port(
             clk             : in std_logic;
             x, y            : in std_logic_vector(9 downto 0);
             onscreen        : out std_logic;
             startvsync      : out std_logic;             
             hsync, vsync    : out std_logic);
end syncmaker;
architecture comparisons of syncmaker is
begin
  process(x, y)
  begin
    if x < 640 and y < 480 and y /= "0000000000" then
      onscreen <= '1';
    else
      onscreen <= '0';
    end if;

    if x > 663 and x < 760 then 
      hsync <= '0'; 
    else 
      hsync <= '1';
    end if;

    -- A bit long on the vsync, but it works. When I went by
    -- the spec, it didn't work on all monitors. Go figure. 
    if y < 491 then
      vsync <= '1';
    else
      vsync <= '0';
    end if;

    if x="0000000000" and y=491 then
      startvsync <= '1';
    else
      startvsync <= '0';
    end if;
  end process;
end comparisons;

