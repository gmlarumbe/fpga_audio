-------------------------------------------------------------------------------
-- Copyright (c) 1995/2018 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/      Version     : 2018.3
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                        General Clock Control Buffer
-- /___/   /\     Filename : BUFGCTRL.vhd
-- \   \  /  \
--  \___\/\___\
--
-------------------------------------------------------------------------------
-- Revision:
--    03/23/04 - Initial version.
--    11/28/05 - CR 221551 fix.
--    08/13/07 - CR 413180 Initialization mismatch fix for unisims.
--    04/07/08 - CR 469973 -- Header Description fix
--    05/22/08 - Add init_done to pass initial values (CR 473625).
--    10/17/12 - 682802 - convert GSR H/L to 1/0
-- End Revision
-------------------------------------------------------------------------------

----- CELL BUFGCTRL -----

library IEEE;
use IEEE.STD_LOGIC_1164.all;


library unisim;
use unisim.vpkg.all;
use unisim.vcomponents.all;

entity BUFGCTRL is

  generic(
      CE_TYPE_CE0 : string := "SYNC";
      CE_TYPE_CE1 : string := "SYNC";
      INIT_OUT     : integer := 0;
      IS_CE0_INVERTED : bit := '0';
      IS_CE1_INVERTED : bit := '0';
      IS_I0_INVERTED : bit := '0';
      IS_I1_INVERTED : bit := '0';
      IS_IGNORE0_INVERTED : bit := '0';
      IS_IGNORE1_INVERTED : bit := '0';
      IS_S0_INVERTED : bit := '0';
      IS_S1_INVERTED : bit := '0';
      PRESELECT_I0 : boolean := false;
      PRESELECT_I1 : boolean := false
    );

  port(
    O		: out std_ulogic;
    CE0		: in  std_ulogic;
    CE1		: in  std_ulogic;
    I0	        : in  std_ulogic;
    I1        	: in  std_ulogic;
    IGNORE0	: in  std_ulogic;
    IGNORE1	: in  std_ulogic;
    S0		: in  std_ulogic;
    S1		: in  std_ulogic
    );
end BUFGCTRL;

architecture BUFGCTRL_V OF BUFGCTRL is

  constant MODULE_NAME : string := "BUFGCTRL";
  constant OUTCLK_DELAY : time := 100 ps;

  constant SYNC_PATH_DELAY : time := 100 ps;

  signal CE0_dly        : std_ulogic := 'X';
  signal CE1_dly        : std_ulogic := 'X';
  signal I0_dly         : std_ulogic := 'X';
  signal I1_dly         : std_ulogic := 'X';
  signal IGNORE0_dly    : std_ulogic := 'X';
  signal IGNORE1_dly    : std_ulogic := 'X';
  signal GSR_I0_dly     : std_ulogic := 'X';
  signal GSR_I1_dly     : std_ulogic := 'X';
  signal S0_dly         : std_ulogic := 'X';
  signal S1_dly         : std_ulogic := 'X';

  signal O_zd		: std_ulogic := 'X';

  signal q0             : std_ulogic := 'X';
  signal q1             : std_ulogic := 'X';
  signal q0_enable      : std_ulogic := 'X';
  signal q1_enable      : std_ulogic := 'X';

  signal preslct_i0     : std_ulogic := 'X';
  signal preslct_i1     : std_ulogic := 'X';

  signal i0_int         : std_ulogic := 'X';
  signal i1_int         : std_ulogic := 'X';
  signal init_done      : boolean := false;
begin

  ---------------------
  --  INPUT PATH DELAYs
  --------------------

  CE0_dly                <= not CE0 when IS_CE0_INVERTED = '1' else CE0;
  CE1_dly                <= not CE1 when IS_CE1_INVERTED = '1' else CE1;
  GSR_I0_dly		 <= TO_X01(GSR);
  GSR_I1_dly		 <= TO_X01(GSR);
  I0_dly                 <= not I0 when IS_I0_INVERTED = '1' else I0;
  I1_dly                 <= not I1 when IS_I1_INVERTED = '1' else I1;
  IGNORE0_dly            <= not IGNORE0 when IS_IGNORE0_INVERTED = '1' else IGNORE0;
  IGNORE1_dly            <= not IGNORE1 when IS_IGNORE1_INVERTED = '1' else IGNORE1;
  S0_dly                 <= not S0 when IS_S0_INVERTED = '1' else S0;
  S1_dly                 <= not S1 when IS_S1_INVERTED = '1' else S1;

  
  --------------------
  --  BEHAVIOR SECTION
  --------------------

--####################################################################
--#####                     Initialize                           #####
--####################################################################
  prcs_init:process
  variable FIRST_TIME : boolean := true;
  variable preslct_i0_var : std_ulogic;
  variable preslct_i1_var : std_ulogic;

  begin
    if(FIRST_TIME) then

      -- check for PRESELECT_I0
      case PRESELECT_I0  is
        when true  => preslct_i0_var := '1';
        when false => preslct_i0_var := '0';
        when others =>
         assert false report
           "*** Attribute Syntax Error: Legal values for PRESELECT_I0 are TRUE or FALSE"
          severity failure;
      end case;

      -- check for PRESELECT_I1
      case PRESELECT_I1  is
        when true  => preslct_i1_var := '1';
        when false => preslct_i1_var := '0';
        when others =>
         assert false report
           "*** Attribute Syntax Error: Legal values for PRESELECT_I0 are TRUE or FALSE"
          severity failure;
      end case;

      -- both preslcts can not be 1 simultaneously 
      if((preslct_i0_var = '1') and (preslct_i1_var = '1')) then
         assert false report
           "*** Attribute Syntax Error: The attributes PRESELECT_I0 and PRESELECT_I1 should not be set to TRUE simultaneously"
          severity failure;
      end if;
        
      -- check for INIT_OUT
      if((INIT_OUT /= 0) and (INIT_OUT /= 1)) then
         assert false report
           "*** Attribute Syntax Error: Legal values for INIT_OUT are 0 or 1 "
          severity failure;
      end if;

      preslct_i0 <= preslct_i0_var;
      preslct_i1 <= preslct_i1_var;
      FIRST_TIME := false;
      init_done <= true;

    end if;
    wait;

  end process prcs_init;


----- *** Start
     
  prcs_clk:process(i0_dly, i1_dly)
  begin
     if(INIT_OUT = 1) then
        i0_int <= NOT i0_dly; 
     else
        i0_int <= i0_dly; 
     end if;

     if(INIT_OUT = 1) then
        i1_int <= NOT i1_dly; 
     else
        i1_int <= i1_dly; 
     end if;
  end process prcs_clk;
--####################################################################
--#####                            I1                          #####
--####################################################################
----- *** Input enable for i1
  prcs_en_i1:process(IGNORE1_dly, i1_int, S1_dly, GSR_I1_dly, q0, init_done)
  variable FIRST_TIME        : boolean    := TRUE;
  begin
      if (((FIRST_TIME) and (init_done)) or (GSR_I1_dly = '1')) then
         q1_enable <= preslct_i1;
         FIRST_TIME := false;
      elsif (GSR_I1_dly = '0') then
         if ((i1_int  = '0') and (IGNORE1_dly = '0')) then 
             q1_enable <= q1_enable;
         elsif((i1_int = '1') or (IGNORE1_dly = '1')) then
             q1_enable <= ((NOT q0) AND (S1_dly));
          end if;
             
      end if;
  end process prcs_en_i1;
    
----- *** Output q1
  prcs_out_i1:process(q1_enable, CE1_dly, i1_int, IGNORE1_dly, GSR_I1_dly, init_done)
  variable FIRST_TIME        : boolean    := TRUE;
  begin
      if (((FIRST_TIME) and (init_done))or (GSR_I1_dly = '1')) then
         q1 <= preslct_i1;
         FIRST_TIME := false;
      elsif (GSR_I1_dly = '0') then
         if ((i1_int  = '1') and (IGNORE1_dly = '0')) then 
             q1 <= q1;
         elsif((i1_int = '0') or (IGNORE1_dly = '1')) then
             if ((CE0_dly='1' and q0_enable='1') and (CE1_dly='1' and q1_enable='1')) then
                q1 <=  'X';
             else
                q1 <=  CE1_dly AND q1_enable;
             end if;
         end if;
      end if;
  end process prcs_out_i1;

--####################################################################
--#####                            I0                          #####
--####################################################################
----- *** Input enable for i0
  prcs_en_i0:process(IGNORE0_dly, i0_int, S0_dly, GSR_I0_dly, q1, init_done)
  variable FIRST_TIME        : boolean    := TRUE;
  begin
      if (((FIRST_TIME) and (init_done)) or (GSR_I0_dly = '1')) then
         q0_enable <= preslct_i0;
         FIRST_TIME := false;
      elsif (GSR_I0_dly = '0') then
         if ((i0_int  = '0') and (IGNORE0_dly = '0')) then 
             q0_enable <= q0_enable;
         elsif((i0_int = '1') or (IGNORE0_dly = '1')) then
             q0_enable <= ((NOT q1) AND (S0_dly));
          end if;
             
      end if;
  end process prcs_en_i0;
    
----- *** Output q0
  prcs_out_i0:process(q0_enable, CE0_dly, i0_int, IGNORE0_dly, GSR_I0_dly, init_done)
  variable FIRST_TIME        : boolean    := TRUE;
  begin
      if (((FIRST_TIME) and (init_done)) or (GSR_I0_dly = '1')) then
         q0 <= preslct_i0;
         FIRST_TIME := false;
      elsif (GSR_I0_dly = '0') then
         if ((i0_int  = '1') and (IGNORE0_dly = '0')) then 
             q0 <= q0;
         elsif((i0_int = '0') or (IGNORE0_dly = '1')) then
             if ((CE0_dly='1' and q0_enable='1') and (CE1_dly='1' and q1_enable='1')) then
                q0 <=  'X';
             else
                q0 <=  CE0_dly AND q0_enable;
             end if;
         end if;
      end if;
  end process prcs_out_i0;

--####################################################################
--#####                          OUTPUT                          #####
--####################################################################
  prcs_selectout:process(q0, q1, i0_int, i1_int)
  variable tmp_buf : std_logic_vector(1 downto 0);
  begin
    tmp_buf := q1&q0;
    case tmp_buf is
      when "01" => O_zd <= I0_dly;
      when "10" => O_zd <= I1_dly;
      when "00" => 
            if(INIT_OUT = 1) then
              O_zd <= '1';
            elsif(INIT_OUT = 0) then
              O_zd <= '0';
            end if;
      when "XX" => 
              O_zd <= 'X';
      when others =>
    end case;
  end process prcs_selectout;
--####################################################################

--####################################################################
--#####                         OUTPUT                           #####
--####################################################################
  prcs_output:process(O_zd)
  begin
-- CR fix for 221551
--      O <= O_zd after SYNC_PATH_DELAY;
      O <= O_zd;
  end process prcs_output;
--####################################################################

end BUFGCTRL_V;

