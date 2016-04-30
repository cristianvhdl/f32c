--
-- Copyright (c) 2016 Emard
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
--
-- $Id$
--

-- emulation of the 32-bit AXI CACHE RAM using BRAM
-- it is useful for d/i cache coherence test.
-- it is not timing exact as real ram on axi.
-- it works system clock synhronous, data sampled on rising edge

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity acram_emu is
    generic (
	C_addr_width: integer := 11 -- address width defines RAM size 11 bits -> 2^11 * 4 byte = 2048*4 = 8K
    );
    port (
	clk: in std_logic;
	-- To physical SRAM signals
	acram_a: in std_logic_vector(C_addr_width-1 downto 0);
	acram_d_wr: in std_logic_vector(31 downto 0);
	acram_d_rd: out std_logic_vector(31 downto 0);
	acram_byte_we: in std_logic_vector(3 downto 0);
	acram_ready: out std_logic;
	acram_en: in std_logic
    );
end acram_emu;

architecture Structure of acram_emu is
    signal R_acram_ready: std_logic := '0';
    signal S_acram_d_rd, R_acram_d_rd: std_logic_vector(31 downto 0);
    signal bram_we: std_logic_vector(3 downto 0);
begin
    ram_emu_4bytes: for i in 0 to 3 generate
    ram_emu_8bit: entity work.bram_true2p_1clk
    generic map (
        dual_port => false,
        pass_thru_a => false,
        data_width => 8,
        addr_width => C_addr_width
    )
    port map (
        clk => clk,
        we_a => bram_we(i),
        addr_a => acram_a(C_addr_width-1 downto 0),
        data_in_a => acram_d_wr(7+i*8 downto i*8), 
        data_out_a => S_acram_d_rd(7+i*8 downto i*8)
    );
    bram_we(i) <= acram_en and acram_byte_we(i);
    process(clk)
    begin
      if rising_edge(clk) then
        if acram_en = '1' then
          R_acram_d_rd <= S_acram_d_rd;
        end if;
        R_acram_ready <= acram_en; -- 1 cycle delay
      end if;
    end process;
    acram_ready <= R_acram_ready and acram_en;
    acram_d_rd <= R_acram_d_rd;
    end generate;
end Structure;
