-- Global FSM. Manages the overall system

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity globalfsm is port(
        clk                                                : in std_logic;
        flex_digit                                         : out std_logic_vector(7 downto 0);
        upr, upg, upb, uphsync, upvsync                    : out std_logic;
        joybl, joybr, joybu, joybd, joyl, joyr, joyu, joyd : in std_logic;
        sw                                                 : in std_logic_vector(7 downto 0);
        unused_pin                                         : inout std_logic_vector(126 downto 0);
        dacred, dacgreen, dacblue                          : out std_logic_vector(7 downto 0);
        dacclk                                             : out std_logic;
        dachsync, dacvsync                                 : out std_logic);
end globalfsm;
architecture fsm of globalfsm is
  component renderman
    port(clk                   : in std_logic;
         x, y                  : in std_logic_vector(31 downto 0);
         z                     : in std_logic_vector(9 downto 0);
         clkctr                : in std_logic_vector(15 downto 0);
         fall                  : out std_logic;
         startvsync            : out std_logic;
         texturize             : in std_logic;
         r, g, b               : out std_logic_vector(7 downto 0);
         hsync, vsync          : out std_logic);
  end component;
  component playball
    port (
      clk            : in  std_logic;
      fall           : in  std_logic;
      go             : in  std_logic;
      joybl, joybr, joybu, joybd : in  std_logic;
      joyl, joyr, joyu, joyd : in  std_logic;
      clkctr         : out std_logic_vector(15 downto 0);
      x, y           : out std_logic_vector(31 downto 0);
      z : out std_logic_vector(9 downto 0));
  end component;
  signal fall, startvsync : std_logic;
  signal x, y, ctr : std_logic_vector(31 downto 0);
  signal z : std_logic_vector(9 downto 0);
  signal r, g, b : std_logic_vector(7 downto 0);
  signal hsync, vsync : std_logic;
  signal clkctr : std_logic_vector(15 downto 0);
begin
  dacred <= r;
  dacgreen <= g;
  dacblue <= b;
  dacclk <= not clk;
  dachsync <= not hsync;
  dacvsync <= not vsync;
  upr <= r(0);
  upb <= b(0);
  upg <= g(0);
  uphsync <= hsync;
  upvsync <= vsync; 
  render1: renderman port map(clk => clk,
                              r => r, g => g, b => b,
                              x => x, y => y,
                              z => z,
                              clkctr => clkctr,
                              fall => fall,
                              startvsync => startvsync,
                              texturize => sw(0),
                              hsync => hsync, vsync => vsync
                              );
  play1: playball port map(clk => clk,
                           fall => fall,
                           go => startvsync,
                           joybl => joybl, joybr => joybr, 
                           joybu => joybu, joybd => joybd, 
                           joyl => joyl, joyr => joyr, 
                           joyu => joyu, joyd => joyd,
                           clkctr => clkctr,
                           x => x, y => y, z => z
                           );
  
  unused_pin <= (others => 'Z');
  --x<=ctr;
  --y<=ctr;
  --process (x, y, ctr, clk, startvsync)
  --begin
  --  if rising_edge(clk) then
  --    if startvsync='1' then
  --      ctr<=ctr - 4096;
  --    end if;
  --  end if;
  --end process;
  flex_digit <= joybl&joybr&joybu&joybd&joyl&joyr&joyu&joyd;
end fsm;
