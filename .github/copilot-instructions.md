# Software Tenets

When generating or modifying code always follow these core principles:

## 1. Simple
## 2. Testable
## 3. Modular

In that order.

Simplicity is paramount. Use the least amount of code necessary to accomplish a task. When faced with multiple solutions, choose the simpler one.

Remember:
"Simple is Beautiful" and as Alan Kay said, "Simple things should be simple, complex things should be possible."

## Implementation Guidelines

- ALWAYS choose the simplest solution over a more complex one
- If there's an existing pattern that accomplishes the task, use it consistently
- Patterns and good practices should be used only when they don't compromise simplicity
- Favor composition over inheritance
- Write self-documenting code with appropriate comments only when necessary
- Consider performance implications but not at the expense of code clarity

## Code Improvement Guidelines

When suggesting improvements to existing code:

1. **Prioritize simplicity over everything else** - Never add complexity unless absolutely necessary
2. **Make minimal, targeted changes** - Suggest no more than 2-3 small changes that have the highest impact
3. **Avoid unnecessary abstractions** - Do not add interfaces, protocols, or wrappers unless they truly simplify the code
4. **Resist over-engineering** - Don't suggest "best practices" that increase complexity without clear benefits
5. **Maintain existing patterns** - Work within the current architecture rather than proposing major refactors
6. **Fix real problems completely** - When a security, performance, or correctness issue is identified, always implement a complete solution rather than documenting or commenting on the problem
7. **Value readability** - Suggest changes that make the code more understandable without reorganizing it
8. **Test impact carefully** - Consider how changes might affect the testability of the code

Always remember: The best code improvement is one that reduces code while preserving functionality.

## Documentation Guidelines

- **Do not create summary files unprompted** - Only create documentation when explicitly requested
- Keep code comments minimal and focused on why, not what
- Let the code be self-documenting through clear naming

## Modular Architecture

We build things out of small reusable components following the unix philosophy. These components have inputs and outputs and complex behavior is implemented by wiring together a network of these components connecting outputs to inputs.

### Component Design Principles:

1. **Pure Input/Output Interface**: Components expose ONLY input/output ports - no public methods
   - **Inputs**: `PassthroughSubject` or `CurrentValueSubject`
   - **Outputs**: `@Published` properties (serves both as output and SwiftUI binding)
   - **Everything else is private**

2. **Component Structure**:
   ```swift
   class MyComponent: ObservableObject {
       let commandInput = PassthroughSubject<Command, Never>()
       @Published var resultOutput = Result()
       private var cancellables = Set<AnyCancellable>()
   }
   ```

3. **Wiring**: Connect outputs to inputs using `.onReceive($component.output)` and `component.input.send()`

4. **No Public Methods**: Use `component.input.send(data)` instead of `component.doSomething()`

This architecture ensures components are truly modular, testable, and composable through pure data flow rather than method calls.
