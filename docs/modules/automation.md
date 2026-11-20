# AUTOMATION Module

> Available since: v3.4.5.dev3 · U series and Ultima

Reports what a script of the **automation editor** does to the editor's live view: which output of which block fired, the error of a step, the events the script lost. The scripts the editor makes call it on their own; you only meet it when you read such a script (the editor's *Show script*) or turn an automation into a script.

The calls cost almost nothing while no editor watches: each returns at once and nothing is recorded. Only the scripts of the automations are reported (a call from another script does nothing).

## Setup

No configuration needed:

```berry
import AUTOMATION
```

## API Reference

| Function | Description |
|----------|-------------|
| `AUTOMATION.fired(node:int, out:int) -> nil` | Block `node` fired its output `out`. `node` is the place of the block in the automation's graph (1, 2, ...: the script's functions `n1`, `n2`, ...; 1..128 are shown), `out` its output (0 or 1, in the order the editor draws them). |
| `AUTOMATION.error(text:string) -> nil` | A step of the script failed with `text`; the editor shows it on the block that fired last. |
| `AUTOMATION.dropped(count:int) -> nil` | `count` changes of the followed entities were lost: the script was busy while its queue (16 changes) was full. |

## Example

What the editor generates for a block that compares an entity and goes on to two other blocks:

```berry
import AUTOMATION
n2 = def (msg)
    if a_match(ENTITY.get("network.connected"), "eq", true) AUTOMATION.fired(2, 0) n3(msg) else AUTOMATION.fired(2, 1) n4(msg) end
end
```

## See Also

- [ENTITY](entity.md) — the entities the automations follow and set
