-- communicator.vhd
--
-- Communications layer with sound system

--syntax error
library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity communicator is port(
             clk       : in std_logic;
             go        : in std_logic;
             y         : in std_logic_vector(15 downto 0);
             vx, vy    : in std_logic_vector(15 downto 0);
             z, vz     : in std_logic_vector(9 downto 0);
             data_out, data_ready : out std_logic;
             data_rcvd : in std_logic
             );
end communicator;
architecture fsm of communicator is
  signal data_buf : std_logic_vector(67 downto 0);
  type StateType is (idle, data_rdy, next_data, data_received);
  attribute enum_encoding : string;
  attribute enum_encoding of StateType:
    type is "00 01 10 11";
  signal p_s, n_s : StateType;
  signal data_rcvd_int : std_logic;
  signal ctr : std_logic_vector(7 downto 0);

begin
  data_out <= data_buf(0);
  
  clocked:process(clk)   
  begin
    if rising_edge(clk) then
      if go='1' then
        data_buf <= y&vx&vy&z&vz;
        p_s <= data_received;
        ctr <= "00000000";
      else
        if p_s=next_data then
          ctr <= ctr + 1;
          data_buf <='0' & data_buf(67 downto 1);
        end if;
        if ctr=72 then
          p_s <= idle;
        else
          p_s <= n_s;
        end if;
      end if;
      data_rcvd_int <= data_rcvd;
    end if;
  end process;
  
  process(p_s, data_rcvd)
  begin
    case p_s is
      when idle =>
        data_ready <= '0';
        n_s <= idle;
      when data_rdy =>
        data_ready <= '1';
        if data_rcvd_int='0' then
          n_s <= data_rdy;
        else
          n_s <= next_data;
        end if;

      when next_data =>
        n_s <= data_received;
        data_ready <= '0';
        
      when data_received =>
        data_ready <= '0';
        if data_rcvd_int='0' then
          n_s <= data_rdy;
        else
          n_s <= data_received;
        end if;
    end case;
  end process;
end fsm;
