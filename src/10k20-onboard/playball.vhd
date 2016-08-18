-- Playball
--
-- Manages gameplay. 

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity playball is port(clk            : in  std_logic;
                        fall           : in  std_logic;
                        go             : in  std_logic;
                        joybl, joybr, joybu, joybd : in  std_logic;
                        joyl, joyr, joyu, joyd : in  std_logic;
                        x, y           : out std_logic_vector(31 downto 0);
                        z : out std_logic_vector(9 downto 0));
end playball;
architecture logic of playball is
  signal xint, yint, vx, vy : std_logic_vector(31 downto 0);
  signal zint, vz : std_logic_vector(9 downto 0);
begin
  x <= xint;
  y <= yint;
  z <= zint;
  process(xint, yint, clk, go, fall, vx, vy)
  begin
    if rising_edge(clk) then
      if go='1' then
        if fall='1' or (zint(9)='0' and zint > 0) then
          xint <= xint + vx;
          yint <= yint + vy;
          if joyl='1' then
            vx <= vx - 256;
          elsif joyr='1' then
            vx <= vx + 256;
          end if;
          if joyu='1' then
            vy <= vy - 256;
          elsif joyd='1' then
            vy <= vy + 256;
          end if;

          if zint="0000000000" and vz="0000000000" and joybl='0' then
            vz <= vz+16;
            zint <= zint + vz;
          elsif vz(9)='1' and (zint="0000000000" or zint(9)='1') then
            vz <= "0000000000";
            zint <= "0000000000";
          elsif zint/="0000000000" then
            vz <= vz - 1;
            zint <= zint + vz;
          else
            zint <= zint + vz;
          end if;
          
        else -- if fall='0'
          vx <= "00000000000000000000000000000000";
          vy <= "00000000000000000000000000000000";
          xint <= "00000000000000000000000000000000";
          yint <= "00000000000000000000000000000000";
          zint <= "0000000000";
          vz <= "0000000000";
        end if;
      end if;
    end if;
  end process;
end logic;
