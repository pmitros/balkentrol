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
        offsetx          : in std_logic_vector(15 downto 0);
        offsety          : in std_logic_vector(15 downto 0);
        xscreen, yscreen : out std_logic_vector(9 downto 0);
        xscreen_prime    : out std_logic_vector(9 downto 0);
        xtrans0, ytrans0 : out std_logic_vector(23 downto 0);
        xtrans1, ytrans1 : out std_logic_vector(23 downto 0);
        offset           : in std_logic);
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

  signal increment0shift1, increment0shift2 : std_logic_vector(23 downto 0);
  signal newxtrans0 : std_logic_vector(23 downto 0);
  signal nextincrement0, increment0 :  std_logic_vector(15 downto 0);
  signal xtransint0, ytransint0 : std_logic_vector(23 downto 0);

  signal increment1shift1, increment1shift2 : std_logic_vector(23 downto 0);
  signal newxtrans1 : std_logic_vector(23 downto 0);
  signal nextincrement1, increment1 :  std_logic_vector(15 downto 0);
  signal xtransint1, ytransint1 : std_logic_vector(23 downto 0);

  signal offset_glass : std_logic_vector(15 downto 0);
begin
  incrementrom1: incrementrom port map(clk=>clk,
                                       vline=>yscreenint(8 downto 0),
                                       increment => nextincrement0);
  nextincrement1 <= ("0" & nextincrement0(15 downto 1)) +
                    ("00" & nextincrement0(15 downto 2)) ;
  
  increment0shift1 <= nextincrement0&"00000000";
  increment0shift2 <= "00"&nextincrement0&"000000";
  newxtrans0 <= 0 - increment0shift1 - increment0shift2 + 524288 +
                 (offsetx&"00000000") + offset_glass;

  increment1shift1 <= nextincrement1&"00000000";
  increment1shift2 <= "00"&nextincrement1&"000000";
  newxtrans1 <= 0 - increment1shift1 - increment1shift2 + 524288 +
                 (offsetx&"00000000") + offset_glass;
  
  process(clk, xscreenint, yscreenint)
  begin
    if rising_edge(clk) then
      -- xscreen calculations
      --if xscreenint /= (640+24+96+48) then
      if xscreenint/="1100101000" then
        xscreenint <= xscreenint + 1;
        xtransint0 <= xtransint0 + increment0;
        xtransint1 <= xtransint1 + increment1;
      --elsif yscreenint /= (480+10+2+32) then
      elsif yscreenint /= "1000001100" then
        xscreenint <= "0000000000";
        xtransint0 <= newxtrans0;
        xtransint1 <= newxtrans1;
        increment0 <= nextincrement0;
        increment1 <= nextincrement1;
        ytransint0 <= ytransint0 + increment0;
        ytransint1 <= ytransint1 + increment1;
        yscreenint <= yscreenint + 1;
      else
        xscreenint <= "0000000000";
        yscreenint <= "0000000000";
        ytransint0 <= offsety&"00000000";
        ytransint1 <= offsety&"00000000";
        xtransint0 <= newxtrans0;
        xtransint1 <= newxtrans1;
      end if;
    end if;
    xscreen <= xscreenint;
    yscreen <= yscreenint;
    xtrans0 <= xtransint0;
    xtrans1 <= xtransint1;
    ytrans0 <= ytransint0;
    ytrans1 <= ytransint1;
    if offset='1' then
      xscreen_prime <= xscreenint + 32;
    else
      xscreen_prime <= xscreenint;
    end if;
  end process;

  -- Shift ball for xscreen
  process(xscreenint, offset)
  begin
    if offset='1' then
      offset_glass <= "1001001010000000";
    else
      offset_glass <= "0000000000000000";
    end if;
  end process;
end fsm;

