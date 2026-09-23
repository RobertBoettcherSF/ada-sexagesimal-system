with Ada.Strings.Unbounded;

package body Sexagesimal_System is

   -----------------------------------------------------------------------------
   --  Pure Base-60 Integer Conversion
   -----------------------------------------------------------------------------

   function To_Sexagesimal (Value : Natural) return Digit_Array is
      --  Natural'Last is 2^31 - 1, which requires at most 6 base-60 digits.
      Temp    : array (1 .. 6) of Sexagesimal_Digit;
      Count   : Natural := 0;
      Current : Natural := Value;
   begin
      if Current = 0 then
         return Digit_Array'(1 => 0);
      end if;

      while Current > 0 loop
         Count := Count + 1;
         Temp (Count) := Sexagesimal_Digit (Current mod 60);
         Current := Current / 60;
      end loop;

      declare
         --  Reverse the array to put the most significant digit first.
         Result : Digit_Array (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Temp (Count - I + 1);
         end loop;
         return Result;
      end;
   end To_Sexagesimal;

   function From_Sexagesimal (Values : Digit_Array) return Natural is
      Result : Natural := 0;
   begin
      if Values'Length = 0 then
         raise Empty_Array_Error;
      end if;

      for I in Values'Range loop
         --  Check for overflow before multiplying
         if Result > Natural'Last / 60 then
            raise Overflow_Error;
         end if;
         Result := Result * 60 + Natural (Values (I));
      end loop;
      
      return Result;
   end From_Sexagesimal;

   -----------------------------------------------------------------------------
   --  Fractional Base-60
   -----------------------------------------------------------------------------

   function Float_To_Fractions (Value : Float; Precision : Precision_Type) return Digit_Array is
      Current_Val : Float := Value;
      Result      : Digit_Array (1 .. Precision);
      Temp_D      : Natural;
   begin
      if Value < 0.0 or else Value >= 1.0 then
         raise Invalid_Value;
      end if;

      for I in 1 .. Precision loop
         Current_Val := Current_Val * 60.0;
         Temp_D := Natural (Float'Truncation (Current_Val));
         
         --  Guard against floating-point inaccuracies pushing the digit to 60.
         if Temp_D > 59 then
            Temp_D := 59;
         end if;
         
         Result (I) := Sexagesimal_Digit (Temp_D);
         Current_Val := Current_Val - Float (Temp_D);
      end loop;
      
      return Result;
   end Float_To_Fractions;

   -----------------------------------------------------------------------------
   --  Modern Coordinates and Angles
   -----------------------------------------------------------------------------

   function To_Angle (Decimal_Degrees : Float) return Angle is
      Is_Negative : constant Boolean := Decimal_Degrees < 0.0;
      Abs_Deg     : constant Float := abs Decimal_Degrees;
      
      D           : Natural := Natural (Float'Truncation (Abs_Deg));
      Remainder   : Float := Abs_Deg - Float (D);
      Total_Secs  : Float := Remainder * 3600.0;
      
      M           : Natural := Natural (Float'Truncation (Total_Secs / 60.0));
      S           : Float := Total_Secs - Float (M * 60);
      Sign        : Sign_Type := Positive;
   begin
      if Is_Negative then
         Sign := Negative;
      end if;

      --  Handle potential rounding rollovers
      if S >= 60.0 then
         S := S - 60.0;
         M := M + 1;
      end if;
      if M >= 60 then
         M := M - 60;
         D := D + 1;
      end if;

      return (Sign, D, Sexagesimal_Digit (M), S);
   end To_Angle;

   function From_Angle (A : Angle) return Float is
      Abs_D   : constant Float := Float (A.Degrees);
      M_Part  : constant Float := Float (A.Minutes) / 60.0;
      S_Part  : constant Float := A.Seconds / 3600.0;
      Val     : constant Float := Abs_D + M_Part + S_Part;
   begin
      if A.Sign = Negative then
         return -Val;
      else
         return Val;
      end if;
   end From_Angle;

   -----------------------------------------------------------------------------
   --  Modern Timekeeping
   -----------------------------------------------------------------------------

   function To_Time (Total_Seconds : Natural) return Time_Duration is
      H        : constant Natural := Total_Seconds / 3600;
      Rem_Secs : constant Natural := Total_Seconds mod 3600;
      M        : constant Natural := Rem_Secs / 60;
      S        : constant Natural := Rem_Secs mod 60;
   begin
      return (H, Sexagesimal_Digit (M), Sexagesimal_Digit (S));
   end To_Time;

   function From_Time (T : Time_Duration) return Natural is
      Threshold : constant Natural := Natural'Last / 3600;
   begin
      if T.Hours > Threshold then
         raise Overflow_Error;
      end if;
      
      return T.Hours * 3600 + Natural (T.Minutes) * 60 + Natural (T.Seconds);
   end From_Time;

   -----------------------------------------------------------------------------
   --  Helper: Formatting
   -----------------------------------------------------------------------------

   function Image_No_Space (D : Sexagesimal_Digit) return String is
      S : constant String := D'Image;
   begin
      --  D is always >= 0, so D'Image always starts with a space.
      return S (2 .. S'Last);
   end Image_No_Space;

   function To_Historical_String (Whole_Part, Frac_Part : Digit_Array) return String is
      use Ada.Strings.Unbounded;
      Result : Unbounded_String;
   begin
      --  Process whole number digits
      if Whole_Part'Length = 0 then
         Append (Result, "0");
      else
         for I in Whole_Part'Range loop
            Append (Result, Image_No_Space (Whole_Part (I)));
            if I /= Whole_Part'Last then
               Append (Result, ",");
            end if;
         end loop;
      end if;

      --  Process fractional digits, separated by a semicolon
      if Frac_Part'Length > 0 then
         Append (Result, ";");
         for I in Frac_Part'Range loop
            Append (Result, Image_No_Space (Frac_Part (I)));
            if I /= Frac_Part'Last then
               Append (Result, ",");
            end if;
         end loop;
      end if;

      return To_String (Result);
   end To_Historical_String;

end Sexagesimal_System;
