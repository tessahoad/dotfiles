# tmux cheatsheet

The prefix is `Ctrl-b`. Press and release it, *then* press the next
key. It is not a chord. `prefix x` below means exactly that.

## Windows (like tabs)

| Key               | Does                                               |
| ----------------- | -------------------------------------------------- |
| `prefix c`        | New window                                         |
| `prefix ,`        | Rename window                                      |
| `prefix n`        | Next window                                        |
| `prefix p`        | Previous window                                    |
| `prefix 0`-`9`    | Jump straight to window N                          |
| `prefix l`        | Toggle back to the last window                     |
| `prefix w`        | Choose a window from a list                        |
| `prefix &`        | Kill the window (asks first)                       |

## Panes (splits within a window)

| Key               | Does                                               |
| ----------------- | -------------------------------------------------- |
| `prefix %`        | Split left/right                                   |
| `prefix "`        | Split top/bottom                                   |
| `prefix` arrow    | Move to the pane in that direction                 |
| `prefix o`        | Cycle through panes                                |
| `prefix z`        | Zoom a pane to full screen (toggle)                |
| `prefix x`        | Kill the pane (asks first)                         |
| `prefix q`        | Show pane numbers                                  |
| `prefix {`        | Swap pane backwards                                |
| `prefix }`        | Swap pane forwards                                 |
| `prefix space`    | Cycle through layouts                              |
| `prefix !`        | Break the pane out into its own window             |

## Sessions

| Key               | Does                                               |
| ----------------- | -------------------------------------------------- |
| `prefix d`        | Detach — everything keeps running                  |
| `prefix s`        | Choose a session from a list                       |
| `prefix $`        | Rename the session                                 |

## Scrolling and copying

A pane's scrollback is not the terminal's. Use copy mode to reach it.

| Key               | Does                                               |
| ----------------- | -------------------------------------------------- |
| `prefix [`        | Enter copy mode                                    |
| arrows, PgUp      | Move around, once in copy mode                     |
| `Ctrl-space`      | Start a selection                                  |
| `Alt-w`           | Copy the selection                                 |
| `q`               | Leave copy mode                                    |
| `prefix ]`        | Paste                                              |
| `prefix ?`        | List every binding there is                        |

The mouse is on: click to focus, drag borders to resize, scroll to
scroll. Dragging selects into tmux's own clipboard; hold Option while
dragging to select for the system clipboard instead.

## Added by this config

| Key               | Does                                               |
| ----------------- | -------------------------------------------------- |
| `prefix \|`       | Split left/right (alias for `%`)                   |
| `prefix -`        | Split top/bottom (alias for `"`)                   |
| `prefix r`        | Reload `~/.tmux.conf`                              |
| `prefix C-x`      | Toggle: type into every pane at once               |
| `prefix C-h`      | This cheatsheet                                    |
| `prefix P`        | Toggle logging this pane to `~/.tmux-logs/`        |

## From a normal shell

| Key                           | Does                                   |
| ----------------------------- | -------------------------------------- |
| `tmux ls`                     | List sessions                          |
| `tmux attach -t NAME`         | Reattach to one                        |
| `tmux kill-session -t NAME`   | Kill one                               |

## tmuxinator (`mux`)

| Key                     | Does                                         |
| ----------------------- | -------------------------------------------- |
| `mux list`              | Show all projects                            |
| `mux start NAME`        | Start, or reattach if it exists              |
| `mux start N key=val`   | Pass an argument; stop first to change it    |
| `mux stop NAME`         | Kill it                                      |
| `mux open NAME`         | Edit the yml                                 |
| `mux debug NAME`        | Print the script instead of running it       |
