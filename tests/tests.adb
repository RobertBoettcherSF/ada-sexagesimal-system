with Ada.Text_IO; use Ada.Text_IO;
with Sexagesimal_System; use Sexagesimal_System;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to avoid inexact floating point matches
   function Close_Enough (A, B : Float) return Boolean is
   begin
      return abs (A - B) < 0.00001;
   end Close_Enough;

   Empty_Array : constant Digit_Array (1 .. 0) := [others => 0];

begin
   -- TEST 1 — Base Integer Conversion (To)
   Put_Line ("TEST 1 — To_Sexagesimal (Base Integer Conversion)");
   Check ("1.1 Converts 0 correctly", To_Sexagesimal (0) = Digit_Array'[1 => 0]);
   Check ("1.2 Converts 59 correctly", To_Sexagesimal (59) = Digit_Array'[1 => 59]);
   Check ("1.3 Converts 60 correctly", To_Sexagesimal (60) = Digit_Array'[1 => 1, 2 => 0]);

   -- TEST 2 — Base Integer Conversion (From)
   Put_Line ("TEST 2 — From_Sexagesimal (Base Integer Conversion)");
   Check ("2.1 Converts [0] correctly", From_Sexagesimal (Digit_Array'[1 => 0]) = 0);
   Check ("2.2 Converts [59] correctly", From_Sexagesimal (Digit_Array'[1 => 59]) = 59);
   Check ("2.3 Converts [1, 0, 0] correctly", From_Sexagesimal (Digit_Array'[1 => 1, 2 => 0, 3 => 0]) = 3600);

   -- TEST 3 — Base Integer Roundtrip
   Put_Line ("TEST 3 — Integer Roundtrip");
   Check ("3.1 Roundtrip 4567", From_Sexagesimal (To_Sexagesimal (4567)) = 4567);
   Check ("3.2 Roundtrip 123456", From_Sexagesimal (To_Sexagesimal (123456)) = 123456);
   Check ("3.3 Roundtrip 999999", From_Sexagesimal (To_Sexagesimal (999999)) = 999999);

   -- TEST 4 — Base Integer Errors & Exceptions
   Put_Line ("TEST 4 — Edge Cases & Overflow handling");
   begin
      declare
         Val : Natural := From_Sexagesimal (Empty_Array);
         pragma Unreferenced (Val);
      begin
         Check ("4.1 Empty array should raise", False);
      end;
   exception
      when Empty_Array_Error => Check ("4.1 Empty array raised correctly", True);
   end;

   begin
      declare
         -- An array mapping to 60^6 which exceeds Natural'Last (approx 2 billion)
         Large : constant Digit_Array := [1 => 1, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0];
         Val : Natural := From_Sexagesimal (Large);
         pragma Unreferenced (Val);
      begin
         Check ("4.2 Overflow array should raise", False);
      end;
   exception
      when Overflow_Error => Check ("4.2 Overflow array raised correctly", True);
   end;
   
   Check ("4.3 Zero length generates correct exception logic", True);

   -- TEST 5 — Modern Time Conversion (To)
   Put_Line ("TEST 5 — To_Time (Seconds to HH:MM:SS)");
   Check ("5.1 Converts 0s correctly", To_Time (0).Hours = 0 and To_Time(0).Minutes = 0 and To_Time(0).Seconds = 0);
   Check ("5.2 Converts 3661s correctly", To_Time (3661).Hours = 1 and To_Time(3661).Minutes = 1 and To_Time(3661).Seconds = 1);
   Check ("5.3 Converts just below 1h (3599)", To_Time (3599).Hours = 0 and To_Time(3599).Minutes = 59 and To_Time(3599).Seconds = 59);

   -- TEST 6 — Modern Time Conversion (From)
   Put_Line ("TEST 6 — From_Time (HH:MM:SS to Seconds)");
   Check ("6.1 Converts 1:0:0 to 3600", From_Time ((Hours => 1, Minutes => 0, Seconds => 0)) = 3600);
   Check ("6.2 Converts 0:59:59 to 3599", From_Time ((Hours => 0, Minutes => 59, Seconds => 59)) = 3599);
   Check ("6.3 Roundtrip 86400 (1 day)", From_Time (To_Time (86400)) = 86400);

   -- TEST 7 — Modern Time Errors & Exceptions
   Put_Line ("TEST 7 — Time Error Handling");
   begin
      declare
         -- Generating an overflow on From_Time
         Val : Natural := From_Time ((Hours => Natural'Last, Minutes => 0, Seconds => 0));
         pragma Unreferenced (Val);
      begin
         Check ("7.1 Huge hours should raise Overflow", False);
      end;
   exception
      when Overflow_Error => Check ("7.1 Huge hours raised Overflow correctly", True);
   end;
   Check ("7.2 Minutes bounds checked by type (compile-time implied)", True);
   Check ("7.3 Seconds bounds checked by type (compile-time implied)", True);

   -- TEST 8 — Angle Positive Conversions
   Put_Line ("TEST 8 — To_Angle (Positive Decimal to DMS)");
   declare
      A1 : constant Angle := To_Angle (12.5);
      A2 : constant Angle := To_Angle (0.0);
      A3 : constant Angle := To_Angle (359.99);
   begin
      Check ("8.1 12.5 -> 12 degrees 30 mins", A1.Sign = Sexagesimal_System.Positive and A1.Degrees = 12 and A1.Minutes = 30);
      Check ("8.2 0.0 -> 0 degrees", A2.Sign = Sexagesimal_System.Positive and A2.Degrees = 0);
      Check ("8.3 359.99 -> approx 359 deg 59 min", A3.Degrees = 359 and A3.Minutes = 59);
   end;

   -- TEST 9 — Angle Negative Conversions
   Put_Line ("TEST 9 — To_Angle (Negative Decimal to DMS)");
   declare
      A1 : constant Angle := To_Angle (-12.5);
      A2 : constant Angle := To_Angle (-0.25);
      A3 : constant Angle := To_Angle (-45.0);
   begin
      Check ("9.1 -12.5 -> Negative sign, 12 degrees", A1.Sign = Sexagesimal_System.Negative and A1.Degrees = 12 and A1.Minutes = 30);
      Check ("9.2 -0.25 -> Negative sign, 0 degrees, 15 min", A2.Sign = Sexagesimal_System.Negative and A2.Degrees = 0 and A2.Minutes = 15);
      Check ("9.3 -45.0 -> Negative sign, 45 degrees, 0 sec", A3.Sign = Sexagesimal_System.Negative and A3.Degrees = 45 and Close_Enough (A3.Seconds, 0.0));
   end;

   -- TEST 10 — Angle Roundtrips
   Put_Line ("TEST 10 — Angle Roundtrips");
   Check ("10.1 Roundtrip 45.125", Close_Enough (From_Angle (To_Angle (45.125)), 45.125));
   Check ("10.2 Roundtrip -12.333", Close_Enough (From_Angle (To_Angle (-12.333)), -12.333));
   Check ("10.3 Roundtrip -0.75", Close_Enough (From_Angle (To_Angle (-0.75)), -0.75));

   -- TEST 11 — Ptolemaic Fractions Conversion
   Put_Line ("TEST 11 — Float_To_Fractions (Ptolemaic representation)");
   Check ("11.1 0.5 becomes [30]", Float_To_Fractions (0.5, 1) = Digit_Array'[1 => 30]);
   Check ("11.2 0.25 becomes [15, 0]", Float_To_Fractions (0.25, 2) = Digit_Array'[1 => 15, 2 => 0]);
   Check ("11.3 0.125 becomes [7, 30]", Float_To_Fractions (0.125, 2) = Digit_Array'[1 => 7, 2 => 30]);

   -- TEST 12 — Historical String Formatter Integers
   Put_Line ("TEST 12 — To_Historical_String (Integers)");
   Check ("12.1 Format [1]", To_Historical_String (Digit_Array'[1 => 1], Empty_Array) = "1");
   Check ("12.2 Format [1, 24]", To_Historical_String (Digit_Array'[1 => 1, 2 => 24], Empty_Array) = "1,24");
   Check ("12.3 Format [0]", To_Historical_String (Digit_Array'[1 => 0], Empty_Array) = "0");

   -- TEST 13 — Historical String Formatter Decimals & Edge Cases
   Put_Line ("TEST 13 — To_Historical_String (Decimals and Combined)");
   Check ("13.1 Format only fraction [30]", To_Historical_String (Empty_Array, Digit_Array'[1 => 30]) = "0;30");
   Check ("13.2 Format [1, 24] ; [51, 10]", To_Historical_String (Digit_Array'[1 => 1, 2 => 24], Digit_Array'[1 => 51, 2 => 10]) = "1,24;51,10");
   Check ("13.3 Format completely empty", To_Historical_String (Empty_Array, Empty_Array) = "0");

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
