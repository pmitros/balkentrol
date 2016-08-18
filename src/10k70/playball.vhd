-- Playball
--
-- Manages gameplay. 
--
-- This is a bit complicated. It could be modularized, but it would
-- cost us space, and space is a luxury we no longer possess. 


library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity playball is port(clk            : in  std_logic;
                        fall0, fall1   : in  std_logic;
                        go             : in  std_logic;
                        joybl, joybr, joybu, joybd : in  std_logic;
                        joyl, joyr, joyu, joyd : in  std_logic;
                        boost : out std_logic_vector(6 downto 0);
                        clkctr         : out std_logic_vector(15 downto 0);
                        x, y           : out std_logic_vector(15 downto 0);
                        vx, vy         : out std_logic_vector(15 downto 0);
                        z              : out std_logic_vector(9 downto 0);
                        vz             : out std_logic_vector(9 downto 0);
                        mode           : out std_logic_vector(1 downto 0));
end playball;
architecture logic of playball is
  signal xint, yint : std_logic_vector(15 downto 0);
  signal vxint, vyint : std_logic_vector(15 downto 0);
  signal zint, nextzint : std_logic_vector(9 downto 0);
  signal vzint : std_logic_vector(9 downto 0);
  signal boost_int : std_logic_vector(7 downto 0);
  signal clkctrint : std_logic_vector(15 downto 0);
  signal modeint : std_logic_vector(1 downto 0);
  signal lastbu, lastbr, lastbd : std_logic;
  signal paused : std_logic;
  signal postgo : std_logic;
begin
  -- Route dummy signals. 
  x <= xint;
  y <= yint;
  z <= zint;
  vx <= vxint;
  vy <= vyint;
  vz <= vzint(9 downto 0);
  clkctr <= clkctrint;
  mode <= modeint;
  boost <= boost_int(6 downto 0);
  nextzint <= zint + vzint;

  process(xint, yint, clk, go, fall0, vxint, vyint)
  begin
    if rising_edge(clk) then
      -- Pause logic
      if go='1' then
        lastbr<=joybr;
        if lastbr='0' and joybr='1' then
          paused <= not paused;
        end if;
      end if;

      -- Boost logic
      -- 
      -- We wait a clock cycle on some of the operations,
      -- since if we don't, something, presumably clock skew,
      -- screws us. We were occasionally getting intermediate
      -- values of boost propagating into vz. 
      postgo <= go;
      if go='1' and paused='1' then
        -- Boost logic
        lastbd <= joybd;
        --Turns out joybl is a bit flakey on out joystick :)
        if (joybd='0' or lastbd='0') and boost_int /= "10111000"
          and joybl='1' then
          boost_int <= boost_int + 1;
        elsif (joybd='1' and lastbd='1') or joybl='0' then
          boost_int <= "10000000";
        else
          boost_int <= "10111000";
        end if;        
      end if;

      -- Coordinate logic
      if go='1' and paused='1' then
        clkctrint <= clkctrint+1;
        -- Main game logic
        --lastzint <= zint;
        if fall0='1' or (zint(9)='0' and zint /= "000000000") then
          xint <= xint + vxint;
          yint <= yint + vyint;
          if joyl='1' then
            vxint <= vxint - 1;
          elsif joyr='1' then
            vxint <= vxint + 1;
          end if;
          if joyu='1' then
            vyint <= vyint - 1;
          elsif joyd='1' then
            vyint <= vyint + 1;
          end if;

          -- -- zint logic
          -- If we are on a plane, and we hit jump, we jump:
          if (zint="0000000000" or (zint="0001110000" and fall1='1')) and
            vzint="0000000000" and joybl='0' then
            vzint <= "00000"&boost_int(7 downto 3);
            zint <= zint;
          -- Otherwise, if we're on the top ledge:
          -- This actually very rarely glitches; we can fix it with
          -- fall1=1 and ((vzint=0 and zint=0001110000) or
          --    (nextzint<=0001110000 and zint > 0001110000))
          -- But that uses more die space. And at the moment, we're
          -- darned low. It doesn't glitch very visably. 
          elsif fall1='1' and (vzint(9)='1' or vzint="0000000000") and
            nextzint <= "0001110000" and zint >= "0001110000" then
            vzint <= (others => '0');
            zint <= "0001110000";
          -- Otherwise, if we're on the bottom ledge:
          elsif (vzint(9)='1' or vzint="0000000000") and
            (zint="0000000000" or zint(9)='1') then
            vzint <= (others => '0');
            zint <= (others => '0');
          -- Otherwise, if we're in the air:
          else
            vzint <= vzint - 1;
            zint <= nextzint;
          end if;
        else -- if fall0='0'
          vxint <= (others => '0');
          vyint <= (others => '0'); 
          xint <= (others => '0');
          yint <= (others => '0');
          zint <= (others => '0');
          vzint <= (others => '0');
        end if;

        -- Parse mode changes
        lastbu <= joybu;
        if lastbu='0' and joybu='1' then
          modeint <= modeint + 1;
        end if;
      end if;
    end if;
  end process;
end logic;
