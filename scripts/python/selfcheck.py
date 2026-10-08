# selfcheck.py — compares your results with independently recomputed answers.
import numpy as np


def check(label, yours, expected, tol=0.01, hint=None):
    """Print ✓ if `yours` matches `expected` (within tol, relative to its size), else ✗."""
    try:
        a = np.squeeze(np.asarray(yours, dtype=float))
        b = np.squeeze(np.asarray(expected, dtype=float))
        close = np.abs(a - b) <= tol * (1 + np.abs(b))
        ok = a.shape == b.shape and bool(np.all(close | (np.isnan(a) & np.isnan(b))))
    except (TypeError, ValueError):
        # Text (or mixed) results must match exactly.
        ok = np.array_equal(np.asarray(yours, dtype=object), np.asarray(expected, dtype=object))
    print(("✓ " if ok else "✗ ") + label)
    if not ok:
        print(f"    yours:    {_show(yours)}")
        print(f"    expected: {_show(expected)}")
        if hint:
            print(f"    hint: {hint}")
    return ok


def _show(x):
    """Numbers as a compact, rounded list; anything else as is."""
    try:
        return np.round(np.asarray(x, dtype=float), 4).tolist()
    except (TypeError, ValueError):
        return x
