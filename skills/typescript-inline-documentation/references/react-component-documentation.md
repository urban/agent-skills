# React Component Documentation

Use this file for prop contracts, defaults, and component-level behavior.

## Example: Props and component docs

```tsx
/**
 * Props for the button component.
 */
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Visual style variant. @defaultValue "primary" */
  variant?: "primary" | "secondary" | "outline";

  /** Button size. @defaultValue "md" */
  size?: "sm" | "md" | "lg";

  /** Disables interaction and shows loading indicator when true. @defaultValue false */
  loading?: boolean;
}

/**
 * Reusable button with consistent styling and accessibility defaults.
 * @param props - Button properties.
 * @returns Rendered button element.
 */
export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", loading = false, children, ...props }, ref) => (
    <button
      ref={ref}
      data-variant={variant}
      data-size={size}
      disabled={loading || props.disabled}
      {...props}
    >
      {children}
    </button>
  ),
);
```
