
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package common_exceptions is
   -- exception codes
   constant EX_CODE_INST_ADDR_MISALIGNED : integer := 0;
   constant EX_CODE_INST_ACCESS_FAULT       : integer := 1;
   constant EX_CODE_ILLEGAL_INST          : integer := 2;
   constant EX_CODE_ENV_BREAKPOINT        : integer := 3;
   constant EX_CODE_LD_ADDR_MISALIGNED    : integer := 4;
   constant EX_CODE_LD_ACCESS_FAULT       : integer := 5;
   constant EX_CODE_ST_ADDR_MISALIGNED    : integer := 6;
   constant EX_CODE_ST_ACCESS_FAULT       : integer := 7;
   constant EX_CODE_ENV_CALL_U_MODE       : integer := 8;
   constant EX_CODE_ENV_CALL_S_MODE       : integer := 9;
   constant EX_CODE_ENV_CALL_M_MODE       : integer := 11;
   constant EX_CODE_INST_PAGE_FAULT       : integer := 12;
   constant EX_CODE_LD_PAGE_FAULT         : integer := 13;
   constant EX_CODE_ST_PAGE_FAULT         : integer := 15;

   constant EXCEPTION_CODE_MAX : integer := 15;
   constant EXCEPT_MIN_PRIORITY : integer := 5;
   subtype t_exception_code is integer range 0 to EXCEPTION_CODE_MAX;
   subtype t_exception_priority is integer range 0 to 6;

   function resolve_sync_exceptions(code1 : t_exception_code;
                                    code2 : t_exception_code)
                                    return t_exception_code;
end common_exceptions;


package body common_exceptions is


   function get_except_priority(code: t_exception_code) return integer is
      variable priority : t_exception_priority;
   begin
      case code is
--         when EX_CODE_BREAKPOINT =>  -- handle breakpoint seperately
--            priority <= 6;
         when EX_CODE_INST_PAGE_FAULT =>
            priority := 5;
         when EX_CODE_INST_ACCESS_FAULT =>
            priority := 4;
         when EX_CODE_ILLEGAL_INST | EX_CODE_INST_ADDR_MISALIGNED |
              EX_CODE_ENV_CALL_U_MODE | EX_CODE_ENV_CALL_S_MODE |
              EX_CODE_ENV_CALL_M_MODE | EX_CODE_ENV_BREAKPOINT =>
            priority := 3;
         when EX_CODE_ST_ADDR_MISALIGNED | EX_CODE_LD_ADDR_MISALIGNED => 
            priority := 2;
         when EX_CODE_ST_PAGE_FAULT | EX_CODE_LD_PAGE_FAULT =>
            priority := 1;
         when EX_CODE_ST_ACCESS_FAULT | EX_CODE_LD_ACCESS_FAULT =>
            priority := 0;
         when others =>
            priority := 0;
      end case;
      
      return priority;
   end function;
   
   
   function resolve_sync_exceptions(code1 : t_exception_code;
                                    code2 : t_exception_code)
                                    return t_exception_code is
      variable code1_priority : t_exception_priority;
      variable code2_priority : t_exception_priority;
   begin
      -- map codes to priority level
      code1_priority := get_except_priority(code1);
      code2_priority := get_except_priority(code2);
      
      if code1_priority >= code2_priority then
         return code1;
      else
         return code2;
      end if;
   end function;
end common_exceptions;
