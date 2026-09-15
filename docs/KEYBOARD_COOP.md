# Two-player shared-keyboard co-op

Open **Play-Keyboard-Coop.cmd** in the project, or extract **builds/Dark-Forest-Gauntlet-Keyboard-Coop.zip** and open the launcher with that name. The normal **Play.cmd** lobby also has a **Two keyboard players + companions** button, with **T** as a shortcut.

Each person owns two different gnomes. The initial pairs are Ember/Ironbark for P1 and Spore/Light for P2. Click any team slot to cycle its character; choosing a character already in another slot swaps the two, keeping all four realms represented. Press **Enter** to begin.

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move | WASD | Arrow keys |
| Basic attack | F | J |
| Realm power | G | K |
| Switch gnome | Q | L |
| Revive nearby fallen gnome | Hold E | Hold U |

**Esc** pauses. Select **Keyboard Controls**, click a binding, then press its replacement key. Bindings save automatically. Keys already assigned to either person and reserved menu keys are rejected. Esc cancels a pending edit. P1's previous Space/Shift attack/power shortcuts also remain available.

## How the pair works

- The larger **P1/P2 arrow** marks the character receiving your input. Your **+** companion follows using the existing obstacle navigation, retreats from nearby enemies and uses basic attacks against visible targets close to the team.
- Companions never activate a realm power themselves. Switch to that character to use it. Holding switch produces one change; holding power while switching cannot trigger an extra cast.
- Every character keeps its position, health and cooldowns. Switching does not teleport, heal or recharge anyone.
- If the controlled gnome falls, control passes to the living partner. You cannot switch onto a downed gnome. Either human's active character can perform the existing nearby two-second revival; revival does not steal control.
- The shared camera includes all four characters. Normal encounter objectives, defeat and victory rules still apply. Returning to selection retains the selected keyboard mode; the lobby's solo/controller button returns to the original input mode.

The controller/solo mode and automatic power showcase remain available separately. Controllers cannot join or claim slots while the paired keyboard mode is active.

## Verification and remaining playtesting

`tools/Test.ps1` runs the original 96 checks plus 30 shared-keyboard checks (126 total), covering independent movement, actual movement of both active gnomes, switching, held-key behavior, persistent health/cooldowns, automatic transfer, companion navigation around walls and basic attacks, revival, pause, owner labels, mode changes and key remapping. Remapping tests write to an isolated artifact configuration rather than the user's saved controls.

Renderer captures of the lobby, bindings and combat are in `artifacts/keyboard-coop/`. `tools/Package-MoonlitRuins.ps1 -KeyboardCoop` builds a separate archive, smoke-tests its launch modes and checks packaged file hashes. The Windows bundle includes Godot's editor-runtime executable and game data; it is a playtest distribution.

The 30 keyboard checks use the actual Compatibility renderer in an offscreen-positioned window, so they require working graphics. The original 96 checks remain headless. Godot's dummy renderer reports a material cleanup error during the keyboard test's repeated scene unloads; the same 30 checks, including unloads, pass without that error in the actual renderer. Engine errors still fail the test runner.

This is the first playable paired-keyboard version. It still needs two people to test comfort and simultaneous key combinations on the actual keyboard. Remapping can help with awkward combinations; software cannot remove a keyboard's hardware rollover limits. Companion tactics are deliberately simple and need human combat feedback.
