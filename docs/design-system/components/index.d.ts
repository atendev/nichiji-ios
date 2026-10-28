export interface ButtonProps {
  /** Visible label: verb first, sentence case, one to three words. */
  label: string;
  /** primary (one per screen), secondary, quiet, or done (the learned state). */
  variant?: "primary" | "secondary" | "quiet" | "done";
  /** Stretch to the full width of the container. */
  block?: boolean;
  onClick?: () => void;
}
/** Returns a DOM button styled with the nj-btn classes from bundle.css. */
export function Button(props: ButtonProps): HTMLButtonElement;
