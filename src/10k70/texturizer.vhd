-- Texturizer
--
-- Generates textures for renderman. May at some point be broken into
-- seperate texture engines. For now, the ball and level map one are
-- trivial enough not to warrant it.

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity texturizer is port(
  clk                             : in std_logic;
  xscreen, yscreen, xscreen_prime : in std_logic_vector(9 downto 0);
  xsource0, ysource0              : in std_logic_vector(23 downto 0);
  z                               : in std_logic_vector(9 downto 0);
  boost                           : in std_logic_vector(5 downto 0);
  clkctr                          : in std_logic_vector(15 downto 0);
  balltexr, balltexg, balltexb    : out std_logic_vector(7 downto 0); 
  backtexr, backtexg, backtexb    : out std_logic_vector(7 downto 0); 
  racetexr, racetexg, racetexb    : out std_logic_vector(7 downto 0); 
  text_sel                        : in std_logic);
end texturizer;
architecture mathengine of texturizer is
  -- Ball texture
  signal notz, notzsubyscr : std_logic_vector(6 downto 0);

  -- Background texture
  signal basex : std_logic_vector(29 downto 0);
  signal basey : std_logic_vector(15 downto 0);
  signal dx : std_logic_vector(24 downto 0);
  signal dy : std_logic_vector(8 downto 0);
begin
  balltexr <= "0"&boost&"0";
  balltexg <= "00000000";
  notz <= not z(6 downto 0);
  notzsubyscr <= notz-yscreen(6 downto 0);
  balltexb <= '1' & notzsubyscr(4 downto 0) & "00";
  
  racetexr <= ('1' & xsource0(15 downto 9)) - ("00"&not yscreen(9 downto 4));
  racetexg <= ('1' & ysource0(15 downto 9)) - ("00"&not yscreen(9 downto 4));
  racetexb <= "1"&not yscreen(9 downto 3);
  
  process(xscreen, yscreen)
  begin
    if rising_edge(clk) then
      if yscreen=0 then
        basey <= (others => '0');
        dy <= "011110000";
      elsif xscreen=0 then
        basey <= basey + (dy(8)&dy(8)&dy(8)&dy(8)&dy(8)&dy(8)&dy(8)&dy);
        dy <= dy - 1;
      end if;

      if xscreen=0 then
        basex <= (others => '0');
        dx <= (basey(15 downto 0)&"00000000")+(basey(15 downto 0)&"000000");
      else
        dx <= dx-basey;
        basex <= basex + (dx(24)&dx(24)&dx(24)&dx(24)&dx(24)&dx(24)&dx(24)&dx(24)&dx);
      end if;
    end if;
  end process;

  process(text_sel, basex, clkctr)
  begin
    if text_sel='1' then 
      backtexr <= basex(19 downto 12)-clkctr(7 downto 0);
      backtexg <= basex(19 downto 12)+85-clkctr(7 downto 0);
      backtexb <= basex(19 downto 12)+171-clkctr(7 downto 0); 
    else
      backtexr <= basex(29 downto 22)-clkctr(7 downto 0);
      backtexg <= basex(29 downto 22)+85-clkctr(7 downto 0);
      backtexb <= basex(29 downto 22)+171-clkctr(7 downto 0); 
    end if;
  end process;
end mathengine;
