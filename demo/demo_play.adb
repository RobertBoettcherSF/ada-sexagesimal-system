--  Terminal demo: live sexagesimal wall clock (HH:MM:SS via To_Time)
--  plus a sample DMS angle readout (To_Angle / historical string).
--  Default: brief live animation (Clear_Screen each frame).
--  --once: single frame, no clear (Mint-safe).

pragma Ada_2022;

with Ada.Calendar;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;
with Sexagesimal_System; use Sexagesimal_System;
with Terminal_UI;
with Terminal_UI.Frame; use Terminal_UI.Frame;
with Terminal_UI.Grid;  use Terminal_UI.Grid;

procedure Demo_Play is
   Outer_W    : constant Positive := 50;
   Live_Ticks : constant Positive := 5;
   Sample_Deg : constant Float := 12.5;

   Live      : Boolean := True;
   Show_Help : Boolean := False;

   function Trim_Nat (N : Natural) return String is
      Img : constant String := N'Image;
   begin
      return Img (Img'First + 1 .. Img'Last);
   end Trim_Nat;

   function Pad2 (N : Natural) return String is
      S : constant String := Trim_Nat (N);
   begin
      if S'Length >= 2 then
         return S (S'Last - 1 .. S'Last);
      else
         return "0" & S;
      end if;
   end Pad2;

   function Format_HMS (T : Time_Duration) return String is
   begin
      return Pad2 (T.Hours mod 100)
        & ":" & Pad2 (Natural (T.Minutes))
        & ":" & Pad2 (Natural (T.Seconds));
   end Format_HMS;

   function Format_DMS (A : Angle) return String is
      Sign_Ch : constant Character :=
        (if A.Sign = Sexagesimal_System.Negative then '-' else '+');
      Sec_I   : constant Natural :=
        Natural (Float'Truncation (A.Seconds));
   begin
      return Sign_Ch
        & Trim_Nat (A.Degrees) & " deg "
        & Pad2 (Natural (A.Minutes)) & " min "
        & Pad2 (Sec_I) & " sec";
   end Format_DMS;

   function Seconds_Of_Day return Natural is
      use Ada.Calendar;
      Now : constant Time := Clock;
      S   : constant Duration := Seconds (Now);
      N   : constant Integer := Integer (S);
   begin
      if N < 0 then
         return 0;
      elsif N > 86_399 then
         return 86_399;
      else
         return Natural (N);
      end if;
   end Seconds_Of_Day;

   function Build_Frame (Tick : Natural; Total : Natural) return String is
      Secs   : constant Natural := Seconds_Of_Day;
      T      : constant Time_Duration := To_Time (Secs);
      A      : constant Angle := To_Angle (Sample_Deg);
      Wholes : constant Digit_Array := To_Sexagesimal (A.Degrees);
      Fracs  : constant Digit_Array :=
        Digit_Array'(1 => A.Minutes,
                     2 => Sexagesimal_Digit
                       (Natural (Float'Truncation (A.Seconds)) mod 60));
      Hist   : constant String := To_Historical_String (Wholes, Fracs);
      Mode   : constant String :=
        (if Live then "live" else "once");
      Lines  : constant String :=
        "SEXAGESIMAL CLOCK  [" & Mode & "]"
        & ASCII.LF
        & "HH:MM:SS   =  " & Format_HMS (T)
        & ASCII.LF
        & "total secs =  " & Trim_Nat (Secs)
        & "   tick " & Trim_Nat (Tick) & "/" & Trim_Nat (Total)
        & ASCII.LF
        & "SAMPLE ANGLE  decimal = 12.5 deg"
        & ASCII.LF
        & "DMS         =  " & Format_DMS (A)
        & ASCII.LF
        & "historical  =  " & Hist;
   begin
      return Make_Status_Box (Lines, Outer_W);
   end Build_Frame;

   procedure Parse_Args is
   begin
      for I in 1 .. Argument_Count loop
         declare
            Arg : constant String := Argument (I);
         begin
            if Arg = "--live" or else Arg = "-l" then
               Live := True;
            elsif Arg = "--once" or else Arg = "-o" then
               Live := False;
            elsif Arg = "--help" or else Arg = "-h" then
               Show_Help := True;
            else
               Put_Line ("unknown argument: " & Arg);
               Put_Line ("usage: demo_play [--live|--once]");
               raise Program_Error;
            end if;
         end;
      end loop;
   end Parse_Args;

begin
   Parse_Args;
   if Show_Help then
      Put_Line ("usage: demo_play [--live|--once]");
      Put_Line ("  (default)  --live briefly (Clear_Screen each frame)");
      Put_Line ("  --live     animate wall-clock HH:MM:SS + sample DMS");
      Put_Line ("  --once     single frame, no clear");
      Put_Line ("make demo / make play / make once");
      return;
   end if;

   if Live then
      for Tick in 1 .. Live_Ticks loop
         declare
            Frame : constant String := Build_Frame (Tick, Live_Ticks);
         begin
            if Contains_ESC (Frame) then
               Put_Line ("internal error: frame contains ESC");
               raise Program_Error;
            end if;
            Terminal_UI.Clear_Screen;
            Terminal_UI.Put_Frame (Frame);
         end;
         Terminal_UI.Pause_Seconds (0.4);
      end loop;
      New_Line;
      Put_Line ("done — live sexagesimal clock ("
                & Trim_Nat (Live_Ticks) & " ticks).");
   else
      declare
         Frame : constant String := Build_Frame (1, 1);
      begin
         if Contains_ESC (Frame) then
            Put_Line ("internal error: frame contains ESC");
            raise Program_Error;
         end if;
         Terminal_UI.Put_Frame (Frame);
      end;
      Put_Line ("done — --once single frame.");
   end if;
end Demo_Play;
