-- textureselect.vhd
--
-- Translates coordinates to generate the curving snake portion of the
-- map.

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity textureselect is port(
  clk                          : in std_logic;
  balltexr, balltexg, balltexb : in std_logic_vector(7 downto 0); 
  backtexr, backtexg, backtexb : in std_logic_vector(7 downto 0); 
  racetexr, racetexg, racetexb : in std_logic_vector(7 downto 0);
  onscreen, ball, shadow, level0, level1 : in std_logic;
  ball0, level00, level01      : out std_logic;
  r0, g0, b0                   : out std_logic_vector(7 downto 0)
  );
end textureselect;
architecture megamux of textureselect is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if onscreen='1' then
        if ball='1' then
          r0 <= balltexr;
          g0 <= balltexg;
          b0 <= balltexb;
        elsif level0='1' then
          if shadow='1' then
--            r0 <= ('0'&racetexr(7 downto 1))+("0"&racetexr(7 downto 1));
--            g0 <= ('0'&racetexg(7 downto 1))+("0"&racetexg(7 downto 1));
--            b0 <= ('0'&racetexb(7 downto 1))+("0"&racetexb(7 downto 1));
            r0 <= ('0'&racetexr(7 downto 1));
            g0 <= ('0'&racetexg(7 downto 1));
            b0 <= ('0'&racetexb(7 downto 1));
          else
            r0 <= racetexr;
            g0 <= racetexg;
            b0 <= racetexb;            
          end if;
        else
          r0 <= backtexr;
          g0 <= backtexg;
          b0 <= backtexb;          
        end if;
      else
        r0 <= "00000000"; g0 <= "00000000"; b0 <= "00000000";
      end if;

      ball0 <= ball;
      level00 <= level0;
      level01 <= level1;
    end if;
  end process;
end megamux;

