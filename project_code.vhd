-- Grillo Valerio

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_reti_logiche is
    port(
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_add   : in std_logic_vector(15 downto 0);
        i_k     : in std_logic_vector(9 downto 0);
        
        o_done  : out std_logic;
        
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    
    -- Dichiarazione interfacce componenti --
    
    component addr_module is
        port ( 
              addr        : in  std_logic_vector(15 downto 0);
              k_word      : in  std_logic_vector(9 downto 0);
              i_counter   : in  std_logic_vector(10 downto 0);
              addr_mem    : out  std_logic_vector(15 downto 0);
              ended       : out std_logic
        );
    end component;
    component counter is
        port ( 
              clk, rst    : in std_logic;
              enable      : in std_logic_vector(2 downto 0);
              num         : out  std_logic_vector(10 downto 0)
        );
    end component;
    component cred_module is
        port ( 
              sel         : in  std_logic;
              cred_mem    : in  std_logic_vector(4 downto 0);
              cred_out    : out std_logic_vector(4 downto 0)
        );
    end component;
    component fsm is
        port ( 
              i, clk, rst, local_done :  in std_logic; 
              o                       :  out std_logic_vector(2 downto 0) 
        ); 
    end component;
    component cred_pp_register is
        port ( 
              clk, rst    : in  std_logic;
              enable      : in  std_logic_vector(2 downto 0);
              x           : in  std_logic_vector(4 downto 0);
              y           : out std_logic_vector(4 downto 0);
              y_mem       : out std_logic_vector(7 downto 0)
        );
    end component;
    component word_pp_register is
        port ( 
              clk, rst, replace  : in  std_logic;
              enable             : in  std_logic_vector(2 downto 0);
              x                  : in  std_logic_vector(7 downto 0);
              y_mem              : out std_logic_vector(7 downto 0)
        );
    end component;
    
    
    -- Dichiarazione segnali interni --
    
    signal index_counter    : std_logic_vector(10 downto 0);
    signal internal_done    : std_logic;
    signal fsm_state        : std_logic_vector(2 downto 0);
    signal replace          : std_logic;
    signal cred_in_service  : std_logic_vector(4 downto 0);
    signal cred_out_service : std_logic_vector(4 downto 0);
    signal word_mux         : std_logic_vector(7 downto 0);
    signal cred_mux         : std_logic_vector(7 downto 0);
    
begin
    
    -- Mapping porte dei componenti --
    
    addr_m: addr_module port map(
            addr       => i_add,
            k_word     => i_k,
            i_counter  => index_counter,
            addr_mem   => o_mem_addr,
            ended      => internal_done
        );
    count: counter port map(
            clk        => i_clk,
            rst        => i_rst,
            enable     => fsm_state,
            num        => index_counter
        );
    cred_m: cred_module port map(
            sel        => replace,
            cred_mem   => cred_out_service,
            cred_out   => cred_in_service
        );
    machine: fsm port map(
            i          => i_start,
            clk        => i_clk,
            rst        => i_rst,
            local_done => internal_done,
            o          => fsm_state    
        );
    c_pp_reg: cred_pp_register port map(
            clk        => i_clk,
            rst        => i_rst,
            enable     => fsm_state,      
            x          => cred_in_service,       
            y          => cred_out_service, 
            y_mem      => cred_mux
        );
    w_pp_reg: word_pp_register port map(
            clk        => i_clk,
            rst        => i_rst,
            replace    => replace,
            enable     => fsm_state,      
            x          => i_mem_data,
            y_mem      => word_mux
        );
        
    -- Process principale di attivazione RAM e o_done --  
        
    controller: process(i_clk, i_rst)
        begin
            if rising_edge(i_clk) then
                if(fsm_state = "011" or fsm_state = "100")then
                    o_mem_en <= '1';
                    o_mem_we <= '1';
                elsif(fsm_state = "001")then
                    o_mem_en <= '1';
                    o_mem_we <= '0';
                else
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                end if;
            end if;
            if (i_rst = '1') then 
                o_done     <= '0';
                o_mem_we   <= '0';
                o_mem_en   <= '0';
            elsif rising_edge(i_clk) then
                if(fsm_state = "101") then
                    o_done <= '1';
                else
                    o_done <= '0';
                end if;
            end if;
    end process;
    
    -- Dataflow interno --
    
    replace <= '1' when i_mem_data /= "00000000" else '0';         --not + comparator
    o_mem_data <= word_mux when fsm_state = "100" else cred_mux;   --mux
    
               
end Behavioral;

-- Specifica dei componenti --
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity addr_module is
    port ( 
          addr            : in  std_logic_vector(15 downto 0);
          k_word          : in  std_logic_vector(9 downto 0);
          i_counter       : in  std_logic_vector(10 downto 0);
          addr_mem        : out std_logic_vector(15 downto 0);
          ended           : out std_logic
    );
end addr_module;

architecture dataflow of addr_module is
    signal double_k    : std_logic_vector(10 downto 0);

begin

    double_k    <= k_word & '0';                            --shift
    addr_mem    <= addr + i_counter;                        --adder
    ended       <= '1' when i_counter = double_k else '0';  --comparator
    
end dataflow;
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity counter is
    port( 
         clk, rst      : in  std_logic;
         enable        : in  std_logic_vector(2 downto 0);
         num           : out std_logic_vector(10 downto 0)
    );
end counter;

architecture Behavioral of counter is
    signal index : std_logic_vector(10 downto 0);
    
    begin
        -- Contatore modulo 2^11
        counter: process(clk, rst)
            begin
                if rst = '1' then
                    index <= (others => '1');
                elsif rising_edge(clk) then
                    if enable = "101" then
                        index <= (others => '1'); -- Reset sincrono
                    elsif enable = "001" or enable = "100" then
                        index <= index + 1;
                    end if;
                end if;
        end process;
        num <= index;
end Behavioral;
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity cred_module is
    port ( 
          sel         : in  std_logic;
          cred_mem    : in  std_logic_vector(4 downto 0);
          cred_out    : out std_logic_vector(4 downto 0)
        );
end cred_module;

architecture dataflow of cred_module is
    signal added, temp      : std_logic_vector(4 downto 0);
    signal sel_internal_mux : std_logic;
    signal zero, max        : std_logic_vector(4 downto 0);

begin

    zero  <= (others => '0');
    max   <= (others => '1');
    added <= cred_mem + max;                                  --adder
    sel_internal_mux <= '1' when cred_mem = zero else '0';    --comparator
    temp     <= added when sel_internal_mux = '0' else        --mux
                zero  when sel_internal_mux = '1' else
                (others => '-');
    cred_out <= temp when sel = '0' else                      --mux
                max when sel = '1' else
                (others => '-');

end dataflow;
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity fsm is 
    port( 
        i, clk, rst, local_done :  in std_logic; 
        o                        :  out std_logic_vector(2 downto 0) 
    ); 
end fsm; 

architecture Behavioral of fsm is
    type state_type is (IDLE, GET_DATA, WAIT_CHECK, WRITE_W, WRITE_C, REINIT);
    signal next_state, current_state: state_type;

    begin
        state_reg: process(clk, rst) 
            begin 
                if rst='1' then 
                    current_state <= IDLE; 
                elsif rising_edge(clk) then 
                    current_state <= next_state; 
                end if; 
        end process; 

        lambda: process(current_state, i, local_done) 
            begin 
                case current_state is 
                  when IDLE => 
                    if i='1' then 
                      next_state <= GET_DATA; 
                    else 
                      next_state <= IDLE; 
                    end if; 
                    
                  when GET_DATA => 
                    if i='1' then 
                      next_state <= WAIT_CHECK;
                    else 
                      next_state <= GET_DATA; 
                    end if;
                    
                  when WAIT_CHECK => 
                    if i='1' then 
                      if local_done = '1' then
                        next_state <= REINIT;
                      else
                        next_state <= WRITE_W;
                      end if;
                    else 
                      next_state <= WAIT_CHECK; 
                    end if; 
                  
                  when WRITE_W => 
                    if i='1' then 
                      next_state <= WRITE_C; 
                    else 
                      next_state <= WRITE_W; 
                    end if;
                    
                  when WRITE_C => 
                    if i='1' then 
                      next_state <= GET_DATA; 
                    else 
                      next_state <= WRITE_C; 
                    end if;
                 
                  when REINIT => 
                    if i='0' then 
                      next_state <= IDLE; 
                    else 
                      next_state <= REINIT; 
                    end if; 
                    
                end case; 
        end process;
        
        delta: process(current_state) 
            begin 
                case current_state is 
                    when IDLE => 
                        o <= "000"; 
                    
                    when GET_DATA => 
                        o <= "001"; 
                    
                    when WAIT_CHECK => 
                        o <= "010"; 
                    
                    when WRITE_W => 
                        o <= "011"; 
                    
                    when WRITE_C => 
                        o <= "100"; 
                    
                    when REINIT => 
                        o <= "101"; 
                    
                end case; 
        end process; 
        
end Behavioral;
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity cred_pp_register is
    port( 
          clk, rst   : in  std_logic;
          enable     : in  std_logic_vector(2 downto 0);
          x          : in  std_logic_vector(4 downto 0);
          y          : out std_logic_vector(4 downto 0);
          y_mem      : out std_logic_vector(7 downto 0)
    );
end cred_pp_register;

architecture Behavioral of cred_pp_register is
    signal temp : std_logic_vector(4 downto 0);

    begin
        process(clk, rst)
            begin
                if rst = '1' then
                    temp <= (others => '0');
                elsif rising_edge(clk) then
                    if (enable = "101") then -- Reset sincrono
                        temp <= (others => '0'); 
                    elsif (enable = "011") then
                        temp <= x;
                    end if;
                end if;
        end process;
        
        y <= temp;
        y_mem <= "000" & temp;

end Behavioral;
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity word_pp_register is
    port( 
          clk, rst, replace  : in  std_logic;
          enable             : in  std_logic_vector(2 downto 0);
          x                  : in  std_logic_vector(7 downto 0);
          y_mem              : out std_logic_vector(7 downto 0)
    );
end word_pp_register;

architecture Behavioral of word_pp_register is
    signal temp : std_logic_vector(7 downto 0);

    begin
        process(clk, rst)
            begin
                if rst = '1' then
                    temp <= (others => '0');
                elsif rising_edge(clk) then
                    if (enable = "101") then -- Reset sincrono
                        temp <= (others => '0'); 
                    elsif ((enable = "011") and (replace = '1')) then
                        temp <= x;
                    end if;
                end if;
        end process;
        
        y_mem <= temp;

end Behavioral;