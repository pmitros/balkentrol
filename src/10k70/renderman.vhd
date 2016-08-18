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
        x, y          : in std_logic_vector(15 downto 0);
        z             : in std_logic_vector(9 downto 0);
        boost         : in std_logic_vector(5 downto 0);
        clkctr        : in std_logic_vector(15 downto 0);
        fall0, fall1  : out std_logic;
        startvsync    : out std_logic;
        r, g, b       : out std_logic_vector(7 downto 0);
        hsync, vsync  : out std_logic;
        mode          : in std_logic_vector(1 downto 0));
end renderman;
architecture fsm of renderman is
  component scanmaker is port(
        clk               : in std_logic;
        offsetx           : in std_logic_vector(15 downto 0);
        offsety           : in std_logic_vector(15 downto 0);
        xscreen, yscreen  : out std_logic_vector(9 downto 0);
        xscreen_prime     : out std_logic_vector(9 downto 0);
        xtrans0, ytrans0  : out std_logic_vector(23 downto 0);
        xtrans1, ytrans1  : out std_logic_vector(23 downto 0);
        offset            : in std_logic);
  end component;

  component animator is port(
    clk                 : in std_logic;
    xsource0i, ysource0 : in std_logic_vector(23 downto 0);
    xsource0            : out std_logic_vector(23 downto 0);
    clkctr              : in std_logic_vector(15 downto 0));
  end component;

  
  component circlemap port (
    clk  : in std_logic;
    x, y     : in std_logic_vector(9 downto 0);
    z        : in std_logic_vector(9 downto 0);
    pixel: out std_logic);
  end component;
  
  component level1map port(
    clk      : in std_logic;
    x, y     : in std_logic_vector(7 downto 0);
    level     : out std_logic);
  end component;

  component level2map port(
    clk      : in std_logic;
    x, y     : in std_logic_vector(7 downto 0);
    level     : out std_logic);
  end component;
  
  component syncmaker port(
    clk             : in std_logic;
    x, y            : in std_logic_vector(9 downto 0);
    onscreen        : out std_logic;
    startvsync      : out std_logic;             
    hsync, vsync    : out std_logic);
  end component;

  component texturizer port(
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
  end component;

  component shadowmap port(
    clk      : in std_logic;
    x, y     : in std_logic_vector(9 downto 0);
    pixel    : out std_logic);
  end component;

  component textureselect port(
    clk                          : in std_logic;
    balltexr, balltexg, balltexb : in std_logic_vector(7 downto 0); 
    backtexr, backtexg, backtexb : in std_logic_vector(7 downto 0); 
    racetexr, racetexg, racetexb : in std_logic_vector(7 downto 0);
    onscreen, ball, shadow, level0, level1 : in std_logic;
    ball0, level00, level01      : out std_logic;
    r0, g0, b0                   : out std_logic_vector(7 downto 0));
  end component;
  
  -- Current coordinates
  signal xscreen, yscreen, xscreen_prime : std_logic_vector(9 downto 0);
  signal xsource0, ysource0 : std_logic_vector(23 downto 0);
  signal xsource1, ysource1 : std_logic_vector(23 downto 0);

  -- Animator
  signal xsource0i : std_logic_vector(23 downto 0);
  signal addon : std_logic_vector(20 downto 0);

  -- State of current pixel
  signal ball, ball0  : std_logic;
  signal level0, level00 : std_logic;
  signal level1, level01 : std_logic;
  signal shadow : std_logic;
  signal onscreen : std_logic;

  -- Textures of current pixel
  signal balltexr, balltexg, balltexb : std_logic_vector(7 downto 0); 
  signal backtexr, backtexg, backtexb : std_logic_vector(7 downto 0); 
  signal racetexr, racetexg, racetexb : std_logic_vector(7 downto 0); 

  -- Color of the current pixel
  signal r0, g0, b0, r1, g1, b1 : std_logic_vector(7 downto 0);
  signal offset : std_logic;
begin
--  shadow <= '1';
  offset <= clkctr(0) and mode(1);
  -- Pipeline stage 1: Generate screen and translated coordinates
  scan1: scanmaker port map(clk=>clk,
                            offsetx => x,
                            offsety => y,
                            xscreen => xscreen,
                            yscreen => yscreen,
                            xscreen_prime => xscreen_prime,
                            xtrans0 => xsource0i,
                            ytrans0 => ysource0,
                            xtrans1 => xsource1,
                            ytrans1 => ysource1,
                            offset => offset);

  -- Pipeline stage 2: Animation of playing field
  anim1: animator port map(clk=>clk,
                           xsource0i=>xsource0i, ysource0=>ysource0,
                           xsource0=>xsource0, clkctr=>clkctr);
  
  -- Pipeline stage 3: Check what we are over, and generate textures
  --   for all the objects
  circle1: circlemap port map(clk => clk,
                             x => xscreen_prime,
                             y => yscreen,
                             z => z,
                             pixel => ball);
  shadow1: shadowmap port map(clk => clk,
                              x => xscreen_prime,
                              y => yscreen,
                              pixel => shadow);
  levelmap1: level1map port map(clk=>clk,
                               x=>xsource0(23 downto 16),
                               y=>ysource0(23 downto 16),
                               level => level0);

  levelmap2: level2map port map(clk=>clk,
                               x=>xsource1(23 downto 16),
                               y=>ysource1(23 downto 16),
                               level => level1);

  syncmaker1: syncmaker port map (clk=>clk,
                                  x => xscreen, y => yscreen,
                                  onscreen => onscreen,
                                  startvsync => startvsync,
                                  hsync => hsync, vsync => vsync);

  text1: texturizer port map(clk=>clk,
                             xscreen=>xscreen, yscreen=>yscreen,
                             xscreen_prime=>xscreen_prime,
                             xsource0=>xsource0, ysource0=>ysource0,
                             boost => boost,
                             z=>z, clkctr=>clkctr,
                             balltexr=>balltexr, balltexg=>balltexg,
                             balltexb=>balltexb, backtexr=>backtexr,
                             backtexg=>backtexg, backtexb=>backtexb,
                             racetexr=>racetexr, racetexg=>racetexg,
                             racetexb=>racetexb,
                             text_sel=>mode(0));

  -- Pipeline stage 4: Demux the proper texture
  --texsel: textureselect port map(clk=>clk,
  --                               balltexr=>balltexr, balltexg=>balltexg,
  --                               balltexb=>balltexb,
  --                               backtexr=>backtexr, backtexg=>backtexg,
  --                               backtexb=>balltexb,
  --                               racetexr=>racetexr, racetexg=>racetexg,
  --                               racetexb=>racetexb,
  --                               onscreen=>onscreen, ball=>ball,
  --                               shadow=>shadow, level0=>level0,
  --                               level1=>level1,
  --                               ball0=>ball0,
  --                               level00=>level00, level01=>level01,
  --                               r0=>r0, g0=>g0, b0=>b0);
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

  
  -- Pipeline stage 5: Handle transparency
  process(xscreen, yscreen)
  begin
-- Stupid tools break if we pipeline this properly
--    if rising_edge(clk) then
    if (level01='1' and onscreen='1') and (ball0='0' or (yscreen>304))then
      r1 <= "0"&r0(7 downto 1);
      g1 <= "1"&g0(7 downto 1);
      b1 <= "1"&b0(7 downto 1);
    else
      r1 <= r0;
      g1 <= g0;
      b1 <= b0;
    end if;
--      end if;
  end process;  
  
  -- Last step of the pipeline - Register the outputs,
  -- so they change precisely on the clock edge
  process(clk, xscreen, yscreen)
  begin
    if rising_edge(clk) then
      r <= r1;
      g <= g1;
      b <= b1;
    end if;
  end process;

  -- Detects whether the ball is falling off the platforms
  process(clk)
  begin
    if rising_edge(clk) then
      if xscreen_prime="0101000001" and yscreen="0110100000" then
        fall0 <= level0;
      end if;

      -- line 0x130=304=100110000
      if xscreen_prime="0101000001" and yscreen="0100110000" then
        fall1 <= level1;
      end if;
    end if;
  end process;
end fsm;

