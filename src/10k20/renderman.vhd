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
        clkctr        : in std_logic_vector(15 downto 0);
        fall          : out std_logic;
        startvsync    : out std_logic;
        texturize     : in std_logic;
        r, g, b       : out std_logic_vector(7 downto 0);
        hsync, vsync  : out std_logic);
end renderman;
architecture fsm of renderman is
  component scanmaker is port(
        clk              : in std_logic;
        offsetx          : in std_logic_vector(31 downto 0);
        offsety          : in std_logic_vector(31 downto 0);
        xscreen, yscreen : out std_logic_vector(9 downto 0);
        xtrans, ytrans   : out std_logic_vector(31 downto 0));
  end component;

  component circlemap
    port (clk  : in std_logic;
          x, y     : in std_logic_vector(9 downto 0);
          z        : in std_logic_vector(9 downto 0);
          pixel: out std_logic);
  end component;
  
  component levelmap
    port(clk      : in std_logic;
         x, y     : in std_logic_vector(15 downto 0);
         level     : out std_logic);
  end component;

  component syncmaker
    port(clk             : in std_logic;
         x, y            : in std_logic_vector(9 downto 0);
         onscreen        : out std_logic;
         startvsync      : out std_logic;             
         hsync, vsync    : out std_logic);
  end component;
  
  -- Current coordinates
  signal xscreen, yscreen : std_logic_vector(9 downto 0);
  signal xsource, ysource : std_logic_vector(31 downto 0);

  -- State of current pixel
  signal ball  : std_logic;
  signal level : std_logic;
  signal onscreen : std_logic;

  -- Textures of current pixel
  signal balltexr, balltexg, balltexb : std_logic_vector(7 downto 0); 
  signal backtexr, backtexg, backtexb : std_logic_vector(7 downto 0); 
  signal racetexr, racetexg, racetexb : std_logic_vector(7 downto 0); 

  -- Temporary for rendering the background
  signal basex : std_logic_vector(30 downto 0);
  signal basey : std_logic_vector(15 downto 0);
  signal dx : std_logic_vector(24 downto 0);
  signal dy : std_logic_vector(8 downto 0);

  -- Ball texture
  signal notz, notzsubyscr : std_logic_vector(6 downto 0);
  
  -- Color of the current pixel
  signal r0, g0, b0 : std_logic_vector(7 downto 0);
begin
  -- Pipeline 1: Generate screen and translated coordinates
  scan1: scanmaker port map(clk=>clk,
                            offsetx => x,
                            offsety => y,
                            xscreen => xscreen,
                            yscreen => yscreen,
                            xtrans => xsource,
                            ytrans => ysource);
  circle1: circlemap port map(clk => clk,
                             x => xscreen,
                             y => yscreen,
                             z => z,
                             pixel => ball);
  levelmap1: levelmap port map(clk=>clk,
                               x=>xsource(31 downto 16),
                               y=>ysource(31 downto 16),
                               level => level);

  syncmaker1: syncmaker port map (clk=>clk,
                                  x => xscreen, y => yscreen,
                                  onscreen => onscreen,
                                  startvsync => startvsync,
                                  hsync => hsync, vsync => vsync);

  balltexr <= "00000000";
  balltexg <= "00000000";
  --balltexb <= "00000000";
  notz <= not z(6 downto 0);
  notzsubyscr <= notz-yscreen(6 downto 0);
  balltexb <= '1' & notzsubyscr(4 downto 0) & "00";

  racetexr <= ('1' & xsource(15 downto 9)) - ("00"&not yscreen(9 downto 4));
  racetexg <= ('1' & ysource(15 downto 9)) - ("00"&not yscreen(9 downto 4));
  racetexb <= "1"&not yscreen(9 downto 3);

  process(xscreen, yscreen)
  begin
	if rising_edge(clk) then
      if yscreen=0 then
        basey <= (others => '0');
        --dy <= "0000000000000000000000011110000";
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

  --backtexr <= (xscreen(4 downto 1)+clkctr(6 downto 3))&(xscreen(8 downto 5)+clkctr(5 downto 2));
  --backtexg <= not yscreen(8 downto 1)+(clkctr(6 downto 0)&'0');
  --backtexb <= yscreen(8 downto 1)+(clkctr(6 downto 0)&'0');
  
  --backtexr <= "00000000";
  --backtexg <= "00000000";
  --backtexb <= "00000000";

  backtexr <= basex(29 downto 22)-clkctr(7 downto 0);
  backtexg <= basex(29 downto 22)+85-clkctr(7 downto 0);
  backtexb <= basex(29 downto 22)+171-clkctr(7 downto 0); 

  process(xscreen, yscreen)
  begin
    if rising_edge(clk) then
      if onscreen='1' then
        if ball='1' then
          r0 <= balltexr;
          g0 <= balltexg;
          b0 <= balltexb;
        elsif level='1' then
          r0 <= racetexr;
          g0 <= racetexg;
          b0 <= racetexb;        
        else
          r0 <= backtexr;
          g0 <= backtexg;
          b0 <= backtexb;          
        end if;
      else
        r0 <= "00000000"; g0 <= "00000000"; b0 <= "00000000";
      end if;

      if xscreen="0101000000" and yscreen="0110100000" then
        fall <= level;
      end if;
    end if;
  end process;

  -- Last step of the pipeline - Register the outputs,
  -- so they change precisely on the clock edge
  process(clk, xscreen, yscreen)
  begin
    if rising_edge(clk) then
      r <= r0;
      g <= g0;
      b <= b0;
    end if;
  end process;
end fsm;

