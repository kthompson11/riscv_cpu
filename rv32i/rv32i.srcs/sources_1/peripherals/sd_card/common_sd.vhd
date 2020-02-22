

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common_sd is
   constant SD_CMD_INDEX_LEN  : integer := 6;
   constant SD_ARG_LEN        : integer := 32;
   constant SD_BLOCK_LEN      : integer := 4;
   
   -- registers
   constant SD_CSD_LEN        : integer := 128;
   
   constant CRC16_LEN         : integer := 16;
   
   constant START_BLOCK_TOKEN : std_logic_vector(7 downto 0) := "11111110";
   
   constant TX_CMD_LEN        : integer := 40;
   constant TX_DATA_LEN       : integer := START_BLOCK_TOKEN'length + SD_BLOCK_LEN * 8;
   
   constant RX_RESP1_LEN      : integer := 8;
   constant RX_RESP3_LEN      : integer := 40;
   constant RX_RESP7_LEN      : integer := 40;
   constant RX_RESP_MAX_LEN   : integer := RX_RESP7_LEN;  -- TODO: choose longest automatically
   constant RX_DATA_LEN       : integer := SD_BLOCK_LEN * 8 + CRC16_LEN;
   constant RX_DATA_RESP_LEN  : integer := 8;
   constant RX_CSD_LEN        : integer := SD_CSD_LEN + CRC16_LEN;
   constant RX_MAX_LEN        : integer := RX_CSD_LEN;  -- TODO: choose longest automatically
   
   type t_rx_type is (RESP_R1, RESP_R3, RESP_R7, DATA_BLOCK, DATA_ERROR_TOKEN, DATA_RESPONSE, DATA_CSD);
   type t_rx_request is record
      rx_type       : t_rx_type;
      crc_enabled   : boolean;
   end record t_rx_request;
   
   type t_tx_type is (TX_CMD_REQ, TX_DATA_REQ);
   type t_tx_request is record
      tx_type        : t_tx_type;
      cmd_index      : integer range 0 to 2**SD_CMD_INDEX_LEN - 1;
      data           : std_logic_vector(SD_BLOCK_LEN * 8 - 1 downto 0);  -- also used for argument (min block len = 4)
   end record t_tx_request;
   
   -- commands for initialization
   type t_dblock_type is (DBLOCK_NONE, DBLOCK_TX, DBLOCK_RX);
   type t_sd_command is record
      cmd_index : integer range 0 to 2**SD_CMD_INDEX_LEN - 1;
      is_app_cmd : boolean;
      argument : std_logic_vector(SD_ARG_LEN - 1 downto 0);
      resp_type : t_rx_type;
      dblock_type : t_dblock_type;
   end record t_sd_command;
   signal SD_CMD0  : t_sd_command := (cmd_index => 0,
                                      is_app_cmd => false,
                                      argument => (others => '0'),
                                      resp_type => RESP_R1,
                                      dblock_type => DBLOCK_NONE);
   signal SD_CMD8  : t_sd_command := (cmd_index => 8,
                                      is_app_cmd => false,
                                      argument => (others => '0'),
                                      resp_type => RESP_R7,
                                      dblock_type => DBLOCK_NONE);
   signal SD_CMD16 : t_sd_command := (cmd_index => 16,
                                      is_app_cmd => false,
                                      argument => X"00000004",
                                      resp_type => RESP_R1,
                                      dblock_type => DBLOCK_NONE);
   signal SD_CMD55 : t_sd_command := (cmd_index => 55,
                                      is_app_cmd => false,
                                      argument => (others => '0'),
                                      resp_type => RESP_R1,
                                      dblock_type => DBLOCK_NONE);
   signal SD_CMD58 : t_sd_command := (cmd_index => 58,
                                      is_app_cmd => false,
                                      argument => (others => '0'),
                                      resp_type => RESP_R3,
                                      dblock_type => DBLOCK_NONE);
   signal SD_CMD59 : t_sd_command := (cmd_index => 59,  -- turn crc on
                                      is_app_cmd => false,
                                      argument => (31 downto 1 => '0') & '1',
                                      resp_type => RESP_R3,
                                      dblock_type => DBLOCK_NONE);
   signal SD_ACMD41 : t_sd_command := (cmd_index => 41,
                                       is_app_cmd => true,
                                       argument => (others => '0'),
                                       resp_type => RESP_R1,
                                       dblock_type => DBLOCK_NONE);
                                       
   type t_resp_lengths is array(t_rx_type) of integer;
   constant RESP_LENGTHS : t_resp_lengths := (RESP_R1 => 8,
                                              RESP_R3 => 40,
                                              RESP_R7 => 40,
                                              DATA_BLOCK => SD_BLOCK_LEN * 8 + CRC16_LEN,
                                              DATA_ERROR_TOKEN => 8,
                                              DATA_RESPONSE => 8,
                                              DATA_CSD => SD_CSD_LEN + CRC16_LEN);
                                              
                                              
   type t_resp_r1 is record
      parameter_error      : std_logic;
      address_error        : std_logic;
      erase_sequence_error : std_logic;
      com_crc_error        : std_logic;
      illegal_command      : std_logic;
      erase_reset          : std_logic;
      in_idle_state        : std_logic;
   end record t_resp_r1;
   function to_resp_r1(response : std_logic_vector) return t_resp_r1;
end common_sd;


package body common_sd is
   function to_resp_r1(response : std_logic_vector) return t_resp_r1 is
      variable res : t_resp_r1;
   begin
      res.parameter_error      := response(6);
      res.address_error        := response(5);
      res.erase_sequence_error := response(4);
      res.com_crc_error        := response(3);
      res.illegal_command      := response(2);
      res.erase_reset          := response(1);
      res.in_idle_state        := response(0);
      return res;
   end to_resp_r1;
end common_sd;