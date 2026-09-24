package Sexagesimal_System
  with SPARK_Mode => On
is
   --  The fundamental unit of a sexagesimal (base-60) number.
   --  Used directly for historical array representations.
   type Sexagesimal_Digit is range 0 .. 59;
   
   --  An array of base-60 digits. Ordered from most-significant to least-significant.
   type Digit_Array is array (Positive range <>) of Sexagesimal_Digit;

   --  Named exceptions for edge cases and validation.
   Empty_Array_Error : exception;
   Overflow_Error    : exception;
   Invalid_Value     : exception;

   -----------------------------------------------------------------------------
   --  Variant 1: Pure Base-60 Integer Conversion (Babylonian Integers)
   -----------------------------------------------------------------------------

   --  Converts a standard natural number into its base-60 representation.
   function To_Sexagesimal (Value : Natural) return Digit_Array
     with Post => To_Sexagesimal'Result'Length > 0;

   --  Converts a base-60 digit array back into a natural number.
   function From_Sexagesimal (Values : Digit_Array) return Natural
     with Pre => Values'Length > 0;

   -----------------------------------------------------------------------------
   --  Variant 2: Fractional / Hellenistic (Ptolemaic) Math
   -----------------------------------------------------------------------------
   
   subtype Precision_Type is Positive range 1 .. 8;

   --  Converts the fractional part of a float into a sequence of base-60 digits.
   function Float_To_Fractions (Value : Float; Precision : Precision_Type) return Digit_Array
     with Pre => Value >= 0.0 and Value < 1.0,
          Post => Float_To_Fractions'Result'Length = Precision;

   -----------------------------------------------------------------------------
   --  Variant 3: Modern Coordinates and Angles (Degrees, Minutes, Seconds)
   -----------------------------------------------------------------------------
   
   type Sign_Type is (Positive, Negative);

   type Angle is record
      Sign    : Sign_Type;
      Degrees : Natural;
      Minutes : Sexagesimal_Digit;
      Seconds : Float;
   end record;

   --  Converts decimal degrees into the sexagesimal angle format.
   function To_Angle (Decimal_Degrees : Float) return Angle;

   --  Converts a sexagesimal angle format back into decimal degrees.
   function From_Angle (A : Angle) return Float;

   -----------------------------------------------------------------------------
   --  Variant 4: Modern Timekeeping (Hours, Minutes, Seconds)
   -----------------------------------------------------------------------------
   
   type Time_Duration is record
      Hours   : Natural;
      Minutes : Sexagesimal_Digit;
      Seconds : Sexagesimal_Digit;
   end record;

   --  Converts a total count of seconds into a time duration.
   function To_Time (Total_Seconds : Natural) return Time_Duration;

   --  Converts a time duration back into total seconds.
   function From_Time (T : Time_Duration) return Natural;

   -----------------------------------------------------------------------------
   --  Helper: Formatting
   -----------------------------------------------------------------------------
   
   --  Formats into the standard historical notation, e.g., "1,24;51,10".
   --  Uses a comma to separate integer digits and a semicolon to denote the radix point.
   function To_Historical_String (Whole_Part, Frac_Part : Digit_Array) return String;

end Sexagesimal_System;
