entity Lab5 is
    Port ( sys_clk : in std_logic;
          reset_btn   : in std_logic;
          S : in std_logic_vector(3 downto 0);
          TMDS, TMDSB : out std_logic_vector(3 downto 0)
          );
end Lab5;

architecture Behavioral of Lab5 is

-- Video Timing Parameters
--1280x720@60HZ
constant HPIXELS_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(1280, 11)); --Horizontal Live Pixels
constant VLINES_HDTV720P  : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(720, 11));  --Vertical Live ines
constant HSYNCPW_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(80, 11));  --HSYNC Pulse Width
constant VSYNCPW_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(5, 11));    --VSYNC Pulse Width
constant HFNPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(72, 11));   --Horizontal Front Porch
constant VFNPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(3, 11));    --Vertical Front Porch
constant HBKPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(216, 11));  --Horizontal Front Porch
constant VBKPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(22, 11));   --Vertical Front Porch

constant pclk_M : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(36, 8));
constant pclk_D : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(24, 8));

constant tc_hsblnk: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1);
constant tc_hssync: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P);
constant tc_hesync: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P);
constant tc_heblnk: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P);
constant tc_vsblnk: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1);
constant tc_vssync: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P);
constant tc_vesync: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P);
constant tc_veblnk: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P);
signal sws_clk: std_logic_vector(3 downto 0); --clk synchronous output
signal sws_clk_sync: std_logic_vector(3 downto 0); --clk synchronous output
signal bgnd_hblnk : std_logic;
signal bgnd_vblnk : std_logic;


signal red_data, green_data, blue_data : std_logic_vector(7 downto 0) := (others => '0');
signal hcount, vcount : std_logic_vector(10 downto 0);
signal hsync, vsync, active : std_logic;
signal pclk : std_logic;
signal clkfb : std_logic;
signal rgb_data : std_logic_vector(23 downto 0) := (others => '0');

signal  s_count : unsigned (26 downto 0):=(others => '0');
signal slow_clk : std_logic := '0';

--yellow
constant COLOR1_RED : std_logic_vector(7 downto 0) := x"FF";
constant COLOR1_GREEN : std_logic_vector(7 downto 0) := x"FF";
constant COLOR1_BLUE : std_logic_vector(7 downto 0) := x"00";

--green
constant COLOR2_RED : std_logic_vector(7 downto 0) := x"00";
constant COLOR2_GREEN : std_logic_vector(7 downto 0) := x"8B";
constant COLOR2_BLUE : std_logic_vector(7 downto 0) := x"00";

--SALMON

constant COLOR3_RED : std_logic_vector(7 downto 0) := x"FF";
constant COLOR3_GREEN : std_logic_vector(7 downto 0) := x"A0";
constant COLOR3_BLUE : std_logic_vector(7 downto 0) := x"7A";


--DODGER BLUE

constant COLOR4_RED : std_logic_vector(7 downto 0) := x"1E";
constant COLOR4_GREEN : std_logic_vector(7 downto 0) := x"90";
constant COLOR4_BLUE : std_logic_vector(7 downto 0) := x"FF";

type state_type is (idle, movel, mover, moveu, moved);
signal state: state_type:= idle;
--signal STATE_LOC: state_type:= L1;


--constant hv : unsigned (10 downto 0) := to_unsigned(400,11);
signal h, v : signed (10 downto 0);
--signal r : signed (10 downto 0);
signal hfmin, hfmax, vfmin, vfmax: signed (10 downto 0);                                                                                                                                                                                                
signal up : signed (10 downto 0) := to_signed(-10, 11);

signal  down : signed (10 downto 0) := to_signed(10, 11);

signal left : signed (10 downto 0) := to_signed(-10, 11);

signal  right : signed (10 downto 0) := to_signed(10, 11);

signal  gap : signed (10 downto 0) := to_signed(10, 11);
--square 1 head
signal hmin : signed (10 downto 0):= to_signed(500, 11);
signal hmax : signed (10 downto 0):= to_signed(550, 11);
signal vmin : signed (10 downto 0) := to_signed(250, 11);
signal vmax : signed (10 downto 0) := to_signed(300, 11);
--- square 2 body
signal hmin2 : signed (10 downto 0):= to_signed(551, 11);
signal hmax2 : signed (10 downto 0):= to_signed(601, 11);
signal vmin2 : signed (10 downto 0) := to_signed(250, 11);
signal vmax2 : signed (10 downto 0) := to_signed(300, 11);

signal diff1 :signed (10 downto 0);
signal diff2 :signed (10 downto 0);
begin
h <= signed (hcount);
v <= signed (vcount);
diff1 <= hmax + 100;
diff2 <= hmin -100;

--Create a PLL that takes in sys_clk and drives the pclk signal.
--pclk should be 74.25MHz
--You may connect the locked output to open - we aren't using it.
--You may connect the reset input to '0' as in Lab4

pixel_clock_gen : entity work.pxl_clk_gen port map (
    clk_in1 => sys_clk,
    clk_out1 => pclk,
    locked => open,
    reset => '0'
);

timing_inst : entity work.timing port map (
tc_hsblnk=>tc_hsblnk, --input
tc_hssync=>tc_hssync, --input
tc_hesync=>tc_hesync, --input
tc_heblnk=>tc_heblnk, --input
hcount=>hcount, --output
hsync=>hsync, --output
hblnk=>bgnd_hblnk, --output
tc_vsblnk=>tc_vsblnk, --input
tc_vssync=>tc_vssync, --input
tc_vesync=>tc_vesync, --input
tc_veblnk=>tc_veblnk, --input
vcount=>vcount, --output
vsync=>vsync, --output
vblnk=>bgnd_vblnk, --output
restart=>reset_btn,
clk=>pclk);

hdmi_controller : entity work.rgb2dvi
    generic map (
        kClkRange => 2
    )
    port map (
        TMDS_Clk_p => TMDS(3),
        TMDS_Clk_n => TMDSB(3),
        TMDS_Data_p => TMDS(2 downto 0),
        TMDS_Data_n => TMDSB(2 downto 0),
        aRst => '0',
        aRst_n => '1',
        vid_pData => rgb_data,
        vid_pVDE => active,
        vid_pHSync => hsync,
        vid_pVSync => vsync,
        PixelClk => pclk,
        SerialClk => '0');
       
       
active <= not(bgnd_hblnk) and not(bgnd_vblnk);
rgb_data <= red_data & green_data & blue_data;

--To simplify the code, I suggest using a combinational process like this, to drive red_data, green_data, and blue_data
--To draw shapes, just add conditions based on hcount and vcount.
--Assign a color to these signals when hcount and vcount are within the shape you want to draw
--And assign zero otherwise, to paint the rest of the screen black.


clock: process (pclk)
begin
        if  rising_edge(pclk) then
            if s_count = 74250000 then
            slow_clk <= '1';
            s_count <= (others => '0');
            else
            s_count <= s_count + 1;
            slow_clk <='0';
            end if;
        end if;
end process clock;

object: process (h, v)
begin


    if h > hmin and h < hmax and v > vmin and v < vmax then
        red_data <= color4_red;
        green_data <= color4_green;
        blue_data <= color4_blue;
    else if h > hmin2 and h < hmax2 and v > vmin2 and v < vmax2 then
          red_data <= color2_red;
          green_data <= color2_green;
          blue_data <= color2_blue;
  --  else
    else
        green_data <= (others => '0');
        blue_data <= (others => '0');
        red_data <= (others => '0');
    end if;
end if;
     
     
     
     
   
    --      green_data <= (others => '0');
      --    blue_data <= (others => '0');
        --  red_data <= (others => '0');
--    end if;
end process object;


 
state_proc: process (pclk)

variable change : integer;



begin
    if rising_edge (pclk) then
        if slow_clk = '1' then
            --if reset_btn = '1' then
            case state is
                when idle =>                  
                   if S = "0001" then
                        state <= movel;
                       
                        end if;
                    if S = "0010" then
                        state <= mover; end if;
                    if S = "0100" then
                        state <= moveu; end if;
                    if S = "1000" then
                       state <= moved; end if;                      
                       change := 0;
                       
               when  movel =>
--                if S = "0010"  then
--                    state <= mover;
                                if change = 0 then
                                    hmin <= hmin + left;
                                    hmax <= hmax + left;
                                    hmin2 <= hmin2 + left;
                                    hmax2 <= hmax2 + left;
                                else
                                    hmin <= hmin + left + to_signed(-41,11);
                                    hmax <= hmax + left + to_signed(-41,11);
                                    vmin2 <= vmin;
                                    vmax2 <= vmax;
                                    change := 0;
                                end if;
                 if S = "0100" then
                    state <= moveu;
                    change := 1;
                    end if;              
                 if S = "1000" then  
                    STATE <= moved;
                    change := 1;
                    end if;
               
              when mover =>            
                               if change = 0 then
                                    hmin <= hmin + right;
                                    hmax <= hmax + right;
                                    hmin2 <= hmin2 + right;
                                    hmax2 <= hmax2 + right;                                  
                               else
                                    hmin <= hmin + right + to_signed(41,11);
                                    hmax <= hmax + right + to_signed(41,11);
                                    vmin2<= vmin;
                                    vmax2<= vmax;
                                    change := 0;          
                                end if;
                 
                  if S = "0100" then
                         state <= moveu;
                         change := 1;
                         end if;
                  if S = "1000" then
                         state <= moved;
                         change := 1;
                         end if;
               
               
               when moveu =>
                               if change = 0 then            
                                    vmin <= vmin + up;
                                    vmax <= vmax +  up;
                                    vmin2 <= vmin2 + up;
                                    vmax2 <= vmax2 + up;
               
                               else
                                    vmin <= vmin + up + to_signed(-41,11);
                                    vmax <= vmax  + up + to_signed(-41,11);
                                    hmin2 <= hmin;
                                    hmax2 <= hmax;
                                    change := 0;
   
                               end if;
                   
                         if S = "0001" then
                         state <= movel;
                         change := 1;
                         end if;  
                         
                         if S = "0010"then
                         state <= mover;
                         change := 1;
                         end if;
           
                when moved =>
                                if change = 0 then
                                    vmin <= vmin + down;
                                    vmax <= vmax + down;
                                    vmin2 <= vmin2 + down;
                                    vmax2 <= vmax2 + down;
                                else            
                                    vmin <= vmin + down + to_signed(41,11);
                                    vmax <= vmax + down + to_signed(41,11);
                                    hmin2 <= hmin;
                                    hmax2 <= hmax;
                                    change := 0;
                                end if;
                             
                    if S = "0001" then
                        state <= movel;
                        change := 1;
                    end if;
                    if S = "0010" then
                        state <= mover;
                        change := 1;
                    end if;
end case;
end if;
end if;    
end process state_proc;  
 
 
 
     

--food : process (h, v)
--begin

--if h> hfmin and h < hfmax and v>vfmin and v< vfmax  then

--        red_data <= color1_red;
--        green_data <= color1_green;
--        blue_data <= color1_blue;
--        else
--        green_data <= (others => '0');
--        blue_data <= (others => '0');
--        red_data <= (others => '0');
--        end if;

--end process food;

--food_loc : process (hfmin, hfmax, vfmin, vfmax,h,v)
--begin


--CASE STATE_LOC is when l1 =>
-- hfmin <=  ;
-- hfmax <= ;
-- vfmin <=;
-- vfmax <=;
 
-- when l2 =>

--hfmin <=
-- hfmax <=
-- vfmin <=
-- vfmax <=

--end case;

--end process food_loc;




--state_proc : process (pclk)
--begin
--    if rising_edge(pclk) then
--        if slow_clk = '1' then
--            case state is
--                when Blue => state <= Red;
--            when Red => state <= Green;
--            when Green => state <= Blue;
--            end case;
--        end if;
--end if;
--end process state_proc;

end Behavioral;
