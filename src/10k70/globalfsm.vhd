-- Global FSM. Manages the overall system

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity globalfsm is port(
        clk                        : in std_logic;
        joybl, joybr, joybu, joybd : in std_logic;
        joyl, joyr, joyu, joyd     : in std_logic;
        unused_pin                 : inout std_logic_vector(126 downto 0);
        dacred, dacgreen, dacblue  : out std_logic_vector(7 downto 0);
        dacclk                     : out std_logic;
        dachsync, dacvsync         : out std_logic;
        left_glass, right_glass    : out std_logic;
        data_out, data_ready       : out std_logic;
        data_rcvd                  : in std_logic);
end globalfsm;
architecture fsm of globalfsm is
  component renderman
    port(clk                   : in std_logic;
         x, y                  : in std_logic_vector(15 downto 0);
         z                     : in std_logic_vector(9 downto 0);
         boost                 : in std_logic_vector(5 downto 0);
         clkctr                : in std_logic_vector(15 downto 0);
         fall0, fall1          : out std_logic;
         startvsync            : out std_logic;
         r, g, b               : out std_logic_vector(7 downto 0);
         hsync, vsync          : out std_logic;
         mode                  : in std_logic_vector(1 downto 0));
  end component;
  component playball
    port (
      clk                        : in  std_logic;
      fall0, fall1               : in  std_logic;
      go                         : in  std_logic;
      joybl, joybr, joybu, joybd : in  std_logic;
      joyl, joyr, joyu, joyd     : in  std_logic;
      boost : out std_logic_vector(5 downto 0);
      clkctr                     : out std_logic_vector(15 downto 0);
      x, y                       : out std_logic_vector(15 downto 0);
      vx, vy                     : out std_logic_vector(15 downto 0);
      z, vz                      : out std_logic_vector(9 downto 0);
      mode                       : out std_logic_vector(1 downto 0));
  end component;
  component communicator
    port(
      clk                  : in std_logic;
      go                   : in std_logic;
      y                    : in std_logic_vector(15 downto 0);
      vx, vy               : in std_logic_vector(15 downto 0);
      z, vz                : in std_logic_vector(9 downto 0);
      data_out, data_ready : out std_logic;
      data_rcvd            : in std_logic);
  end component; 
    
  signal fall0, fall1, startvsync : std_logic;
  signal x, y, ctr : std_logic_vector(15 downto 0);
  signal vx, vy : std_logic_vector(15 downto 0);
  signal z, vz : std_logic_vector(9 downto 0);
  signal r, g, b : std_logic_vector(7 downto 0);
  signal hsync, vsync : std_logic;
  signal clkctr : std_logic_vector(15 downto 0);
  signal mode : std_logic_vector(1 downto 0);
  signal boost : std_logic_vector(5 downto 0);
begin
  left_glass <= clkctr(0);
  right_glass <= not clkctr(0);
  dacred <= r;
  dacgreen <= g(7)&g(6)&g(5)&g(4)&g(3)&g(2)&g(1)&g(0);
  dacblue <= b;
  dacclk <= '0';
  dachsync <= not hsync;
  dacvsync <= not vsync;
  render1: renderman port map(clk => clk,
                              r => r, g => g, 
                              b => b,
                              x => x, y => y,
                              z => z,
                              boost => boost,
                              clkctr => clkctr,
                              fall0 => fall0,
                              fall1 => fall1,
                              startvsync => startvsync,
                              hsync => hsync, vsync => vsync,
                              mode => mode);
  play1: playball port map(clk => clk,
                           fall0 => fall0,
                           fall1 => fall1,
                           go => startvsync,
                           joybl => joybl, joybr => joybr, 
                           joybu => joybu, joybd => joybd, 
                           joyl => joyl, joyr => joyr, 
                           joyu => joyu, joyd => joyd,
                           boost => boost,
                           clkctr => clkctr,
                           x => x, y => y, z => z,
                           vx => vx, vy => vy, vz => vz,
                           mode => mode);

  com1 : communicator port map(
             clk => clk, go => startvsync,
             y => y, vx => vx, vy => vy,
             z => z, vz => vz,
             data_out => data_out, data_ready => data_ready,
             data_rcvd => data_rcvd);
  
  unused_pin <= (others => 'Z');
end fsm;
