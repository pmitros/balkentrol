-- animator.vhd
--
-- Translates coordinates to generate the curving snake portion of the
-- map.

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity animator is port(
             clk                 : in std_logic;
             xsource0i, ysource0 : in std_logic_vector(23 downto 0);
             xsource0            : out std_logic_vector(23 downto 0);
             clkctr              : in std_logic_vector(15 downto 0));
end animator;
architecture mathengine of animator is
  signal addon : std_logic_vector(20 downto 0);
begin
  addon <= (clkctr(9 downto 0) & "00000000000") +
           ysource0(20 downto 0);
  process (clk)
  begin  -- process
    if rising_edge(clk) then
      if -- ysource0>"000000001000000000000000" and
         ysource0(22 downto 21)="10" then
        if addon(19)='0' then
          xsource0 <= xsource0i+addon(18 downto 0);
        else
          xsource0 <= xsource0i+(not addon(18 downto 0));
        end if;
      else
        xsource0 <= xsource0i;
      end if;
    end if;
  end process;
end mathengine;

