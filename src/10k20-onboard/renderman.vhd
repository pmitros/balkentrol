-- Renderman
--
-- The global rendering engine. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity renderman is port(
        clk           : in std_logic;
        x, y          : in std_logic_vector(31 downto 0);
        z             : in std_logic_vector(9 downto 0);
        fall          : out std_logic;
        startvsync    : out std_logic;
        texturize     : in std_logic;
        r, g, b, hsync, vsync : out std_logic);
end renderman;
architecture fsm of renderman is
  component circlerom
    port (clk  : in std_logic;
          x, y : in std_logic_vector(4 downto 0);
          pixel: out std_logic);
  end component;
  
  component scanmaker is port(
        clk              : in std_logic;
        offsetx          : in std_logic_vector(31 downto 0);
        offsety          : in std_logic_vector(31 downto 0);
        xscreen, yscreen : out std_logic_vector(9 downto 0);
        xtrans, ytrans   : out std_logic_vector(31 downto 0));
  end component;

  component levelrom
    port(clk      : in std_logic;
         x, y     : in std_logic_vector(15 downto 0);
         rect     : out std_logic);
  end component;

  signal r0, g0, b0 : std_logic;
  signal ball_rom, ball  : std_logic;
  signal xscreen, yscreen : std_logic_vector(9 downto 0);
  signal yscreenballmin, yscreenballmax : std_logic_vector(9 downto 0);
  signal incrementshift1, incrementshift2, newxsource1 : std_logic_vector(31 downto 0);
  signal nextincrement, increment : std_logic_vector(15 downto 0);
  signal xsource, ysource, ctr, xoff : std_logic_vector(31 downto 0);
  signal rect : std_logic;
  signal romy : std_logic_vector(4 downto 0);
begin
  --romy <= "00000";
  romy <= yscreen(4 downto 0)+z(4 downto 0);
  yscreenballmin <= 383 - z;
  yscreenballmax <= 416 - z;
  circle1: circlerom port map(clk => clk,
                             x => xscreen(4 downto 0),
                             y => romy, -- yscreen(4 downto 0),
                             pixel => ball_rom);
  scan1: scanmaker port map(clk=>clk,
                            offsetx => x,
                            offsety => y,
                            xscreen => xscreen,
                            yscreen => yscreen,
                            xtrans => xsource,
                            ytrans => ysource);
  levelrom1: levelrom port map(clk=>clk,
                               x=>xsource(31 downto 16),
                               y=>ysource(31 downto 16),
                               rect => rect);

  xoff <= (others => '0');
  
  process(clk, xscreen, yscreen)
  begin
    if rising_edge(clk) then
      r <= r0;
      g <= g0;
      b <= b0;
    end if;
  end process;

  
  process(xscreen, yscreen)
  begin
    if xscreen < 640 and yscreen < 480 then
      hsync <= '1'; vsync <= '1';
      if yscreen=0 or rect='0' or ball='1' then
        r0 <= '0'; g0 <= '0'; 
      else
        g0 <= '1';
        if texturize='0' or xsource(15 downto 10)<ysource(15 downto 10) then
          r0 <= '1';  
        else
          r0 <= '0';
        end if;
      end if;
      b0 <= ball;
      --r <= xsource(21); g <= ysource(21); hsync <= '1'; vsync <= '1';      
      if xscreen > 303 and xscreen < 336 and
         yscreen > yscreenballmin and yscreen < yscreenballmax then 
        ball <= ball_rom;
      else
        ball <= '0';
      end if;
    else
      r0 <= '0'; g0 <= '0'; b0 <= '0';
      if xscreen > 663 and xscreen < 760 then 
        hsync <= '0'; 
      else 
        hsync <= '1';
      end if;
      -- A bit long on the vsync, but it works. 
      if yscreen < 491 then
        vsync <= '1';
      else
        vsync <= '0';
      end if;
    end if;
    if xscreen="0101000000" and yscreen="0110100000" then
      fall <= rect;
    end if;
    if xscreen="0000000000" and yscreen=491 then
      startvsync <= '1';
    else
      startvsync <= '0';
    end if;
  end process;
end fsm;
