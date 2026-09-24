# ada-sexagesimal-system

Ada 2022 package for **sexagesimal (base-60)** numbers: Babylonian integers, Ptolemaic fractions, DMS angles, HMS time, and historical string notation.

## Variants (`src/sexagesimal_system.ads`)

| Variant | API | Notes |
|---------|-----|-------|
| Integer (Babylonian) | `To_Sexagesimal` / `From_Sexagesimal` | Digits `0 .. 59`, MSB first |
| Ptolemaic fractions | `Float_To_Fractions` | Fractional part → base-60 digits |
| DMS angles | `To_Angle` / `From_Angle` | Degrees, minutes, seconds + sign |
| HMS time | `To_Time` / `From_Time` | Total seconds ↔ hours:minutes:seconds |
| Historical string | `To_Historical_String` | e.g. `1,24;51,10` (`;` = radix) |

## Layout

```
src/sexagesimal_system.ads|.adb   public API
tests/tests.adb                   unit tests (~39)
demo/demo_play.adb                Terminal-UI clock / angle demo
third_party/terminal_ui/          vendored Ada-Terminal-UI src/
Makefile  sexagesimal_system.gpr
```

TUI from [Ada-Terminal-UI](https://github.com/RobertBoettcherSF/Ada-Terminal-UI); update by copying `src` when upstream changes.

## Build / test / demo

```bash
make test              # unit tests (-gnatwa -gnat2022)
make demo              # brief live HH:MM:SS + sample DMS (Clear_Screen)
make play              # same as demo
make once              # single frame, no clear
make play ONCE=1       # same as once
./bin/demo_play --once
./bin/demo_play --live
```

## License

MIT. LLM assistance was used for this project.
