Our project uses Godot 4.4. Use the latest syntax and features of GDScript 4.4 when generating code. Follow the guidelines below:

- **Prioritize Explicit Typing:** Always suggest explicit type hints. Godot 4 support typed arrays, so use them when possible. For example, use `Array[int]` instead of `Array`.
- **Use custom classes instead of dictionaries:** Prefer using custom classes over dictionaries for data structures.
- **Use New Signal Syntax:** Prefer the `signal` keyword and the `signal_name.connect(rsignal_name)` method on the signal itself. Name all signals with a `signal_` prefix, and connection functions with `rsignal_`.
- **Encourage `@export`:** Use the `@export` annotation for exported variables.
- **Never use `@onready var x = $Node2D`**: Avoid using the `$` shorthand for node paths. Always export a variable for the node and use that variable to access the node.
- **Suggest `await` keyword** Use `await` to handle asynchronous operations.
- **Use `null` instead of `Nil`**

In our project, states are implemented as separate classes that extends State. `p` gives the entity that has the state (e.g. player), `sm` is the state machine, functions `enter`, `exit`, `physics_update` and `update` can be used and are automatically called. Use `sm.on_child_transition(self, "SomeStateName")` to transition to another state.

Private functions and attributes should start with an underscore `_`.
