-- Scanmaker
--
-- Generates the x, y screen coordinates, as well as the
-- translated screen coordinates. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity scanmaker is port(
        clk              : in std_logic;
        offsetx          : in std_logic_vector(31 downto 0);
        offsety          : in std_logic_vector(31 downto 0);
        xscreen, yscreen : out std_logic_vector(9 downto 0);
        xtrans, ytrans   : out std_logic_vector(31 downto 0));
end scanmaker;
architecture fsm of scanmaker is
  component incrementrom
    port(clk       : in std_logic;
         vline     : in std_logic_vector(8 downto 0);
         increment : out std_logic_vector(15 downto 0);
         initposx  : out std_logic_vector(23 downto 0);
         initposy  : out std_logic_vector(22 downto 0));
  end component;

  signal xscreenint : std_logic_vector(9 downto 0);
  signal yscreenint : std_logic_vector(9 downto 0);
  signal incrementshift1, incrementshift2, newxsource : std_logic_vector(31 downto 0);
  signal nextincrement, increment : std_logic_vector(15 downto 0);
  signal xsourceint, ysourceint : std_logic_vector(31 downto 0);
begin
  incrementrom1: incrementrom port map(clk=>clk,
                                       vline=>yscreenint(8 downto 0),
                                       increment => nextincrement);

  incrementshift1 <= "00000000"&nextincrement&"00000000";
  incrementshift2 <= "0000000000"&nextincrement&"000000";
  newxsource <= 0 - incrementshift1 - incrementshift2 + 524288 + offsetx;
  process(clk, xscreenint, yscreenint)
  begin
    if rising_edge(clk) then
      -- xscreen calculations
      --if xscreenint /= (640+24+96+48) then
      if xscreenint/="1100101000" then
        xscreenint <= xscreenint + 1;
        xsourceint <= xsourceint + increment;
      --elsif yscreenint /= (480+10+2+32) then
      elsif yscreenint /= "1000001100" then
        xscreenint <= "0000000000";
        xsourceint <= newxsource;
        increment <= nextincrement;
        ysourceint <= ysourceint + increment;
        yscreenint <= yscreenint + 1;
      else
        xscreenint <= "0000000000";
        yscreenint <= "0000000000";
        ysourceint <= offsety;
        xsourceint <= newxsource;
      end if;
    end if;
    xscreen <= xscreenint;
    yscreen <= yscreenint;
    xtrans <= xsourceint;
    ytrans <= ysourceint;
  end process;
end fsm;

